#!/usr/bin/env python3
"""Shared linear regression helpers for USD/m² prediction."""

from __future__ import annotations

import math
import statistics
from typing import Any

import numpy as np

FEATURE_NAMES = [
    "bias",
    "area",
    "log_area",
    "rooms",
    "rooms_missing",
    "bedrooms",
    "bedrooms_missing",
    "bathrooms",
    "bathrooms_missing",
    "year",
    "year_missing",
    "building_floors",
    "building_floors_missing",
    "apartment_floor",
    "apartment_floor_missing",
]

MIN_MODEL_LISTINGS = 200
RIDGE_EPS = 1e-6  # tiny ridge for numerical stability only


def impute_defaults(rows: list[dict]) -> dict[str, float]:
    def median_or(key: str, fallback: float) -> float:
        values = [row[key] for row in rows if row.get(key) is not None]
        return float(statistics.median(values)) if values else fallback

    return {
        "rooms": median_or("rooms", 2.0),
        "bedrooms": median_or("bedrooms", 1.0),
        "bathrooms": median_or("bathrooms", 1.0),
        "year": median_or("year", 2010.0),
        "building_floors": median_or("building_floors", 5.0),
        "apartment_floor": median_or("apartment_floor", 2.0),
    }


def feature_vector(
    *,
    area: float,
    rooms: float | None,
    bedrooms: float | None,
    bathrooms: float | None,
    year: float | None,
    building_floors: float | None,
    apartment_floor: float | None,
    defaults: dict[str, float],
) -> np.ndarray:
    def filled(value: float | None, key: str) -> tuple[float, float]:
        if value is None:
            return defaults[key], 1.0
        return float(value), 0.0

    rooms_v, rooms_m = filled(rooms, "rooms")
    bedrooms_v, bedrooms_m = filled(bedrooms, "bedrooms")
    bathrooms_v, bathrooms_m = filled(bathrooms, "bathrooms")
    year_v, year_m = filled(year, "year")
    floors_v, floors_m = filled(building_floors, "building_floors")
    apt_v, apt_m = filled(apartment_floor, "apartment_floor")
    area_v = float(area)

    return np.array(
        [
            1.0,
            area_v,
            math.log(max(area_v, 1.0)),
            rooms_v,
            rooms_m,
            bedrooms_v,
            bedrooms_m,
            bathrooms_v,
            bathrooms_m,
            year_v,
            year_m,
            floors_v,
            floors_m,
            apt_v,
            apt_m,
        ],
        dtype=np.float64,
    )


def design_matrix(rows: list[dict], defaults: dict[str, float]) -> np.ndarray:
    return np.vstack(
        [
            feature_vector(
                area=row["area"],
                rooms=row.get("rooms"),
                bedrooms=row.get("bedrooms"),
                bathrooms=row.get("bathrooms"),
                year=row.get("year"),
                building_floors=row.get("building_floors"),
                apartment_floor=row.get("apartment_floor"),
                defaults=defaults,
            )
            for row in rows
        ]
    )


def standardize_fit(x: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    mean = x.mean(axis=0)
    std = x.std(axis=0)
    mean[0] = 0.0
    std[0] = 1.0
    std = np.where(std < 1e-8, 1.0, std)
    return (x - mean) / std, mean, std


def fit_linear(x: np.ndarray, y: np.ndarray) -> np.ndarray:
    """Ordinary least squares with tiny ridge for invertibility."""
    n_features = x.shape[1]
    penalty = np.eye(n_features) * RIDGE_EPS
    penalty[0, 0] = 0.0
    return np.linalg.solve(x.T @ x + penalty, x.T @ y)


def train_city_model(rows: list[dict]) -> dict[str, Any] | None:
    if len(rows) < MIN_MODEL_LISTINGS:
        return None

    defaults = impute_defaults(rows)
    x_raw = design_matrix(rows, defaults)
    x, mean, std = standardize_fit(x_raw)
    y = np.log(np.array([row["ppm2"] for row in rows], dtype=np.float64))
    weights = fit_linear(x, y)

    near_80 = [row for row in rows if 60.0 <= row["area"] <= 100.0]
    profile = impute_defaults(near_80 if len(near_80) >= 20 else rows)

    return {
        "type": "linear_log_ppm2",
        "loss": "mse_log_ppm2",
        "n": len(rows),
        "features": FEATURE_NAMES,
        "weights": [round(float(v), 8) for v in weights],
        "mean": [round(float(v), 8) for v in mean],
        "std": [round(float(v), 8) for v in std],
        "defaults": {key: round(value, 4) for key, value in defaults.items()},
        "profile": {key: round(value, 4) for key, value in profile.items()},
    }
