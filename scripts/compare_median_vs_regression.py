#!/usr/bin/env python3
"""Train a per-city regression for USD/m² and compare it with the median method.

For capitals with enough apartment listings (>= MIN_MODEL_LISTINGS), we:
  1. Build features from condo attributes (area, rooms, year, floors, ...).
  2. Train Ridge regression with MSE loss on log(USD/m²).
  3. Evaluate on a held-out test set against a median USD/m² baseline.
  4. Form an 80 m² city-level estimate from both methods.

The median remains the right default for thin cities; this script checks whether
feature-aware regression improves held-out error where data is plentiful.
"""

from __future__ import annotations

import csv
import json
import math
import statistics
import sys
from dataclasses import asdict, dataclass
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from build_capitals import (  # noqa: E402
    CAPITALS,
    CSV_PATH,
    MAX_AREA_M2,
    MIN_AREA_M2,
    STANDARD_M2,
    is_apartment,
    location_is_city,
    parse_area,
    parse_price,
    title_of,
)

OUT_DIR = ROOT / "scripts" / "output"
OUT_JSON = OUT_DIR / "median_vs_regression.json"
OUT_MD = OUT_DIR / "median_vs_regression.md"

MIN_MODEL_LISTINGS = 500
TEST_FRACTION = 0.2
RANDOM_SEED = 42
RIDGE_LAMBDAS = (0.1, 1.0, 10.0, 100.0, 1000.0)

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


@dataclass
class CityResult:
    city: str
    country: str
    n_total: int
    n_train: int
    n_test: int
    lambda_: float
    median_ppm2: float
    model_ppm2_at_80: float
    median_price_80: int
    model_price_80: int
    # Held-out listing errors (USD / m²)
    median_mae_ppm2: float
    model_mae_ppm2: float
    median_rmse_ppm2: float
    model_rmse_ppm2: float
    # Held-out listing errors (total USD for that listing's area)
    median_mae_price: float
    model_mae_price: float
    better_on_mae: str
    mae_improvement_pct: float


def parse_float(value: str | None) -> float | None:
    if not value:
        return None
    try:
        number = float(value)
    except ValueError:
        return None
    if math.isnan(number):
        return None
    return number


def load_city_rows() -> dict[str, list[dict]]:
    buckets: dict[str, list[dict]] = {country: [] for country in CAPITALS}
    with CSV_PATH.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            raise ValueError("CSV has no header")
        title_key = reader.fieldnames[0]
        for row in reader:
            country = (row.get("country") or "").strip()
            if country not in CAPITALS:
                continue
            title = title_of(row, title_key)
            if not is_apartment(title):
                continue
            price = parse_price(row.get("price_in_USD"))
            area = parse_area(row.get("apartment_total_area")) or parse_area(
                row.get("apartment_living_area")
            )
            if price is None or area is None:
                continue
            if area < MIN_AREA_M2 or area > MAX_AREA_M2:
                continue
            _, _, aliases = CAPITALS[country]
            if not location_is_city(row.get("location") or "", country, aliases):
                continue
            ppm2 = price / area
            if ppm2 <= 0:
                continue
            buckets[country].append(
                {
                    "price": price,
                    "area": area,
                    "ppm2": ppm2,
                    "rooms": parse_float(row.get("apartment_rooms")),
                    "bedrooms": parse_float(row.get("apartment_bedrooms")),
                    "bathrooms": parse_float(row.get("apartment_bathrooms")),
                    "year": parse_float(row.get("building_construction_year")),
                    "building_floors": parse_float(row.get("building_total_floors")),
                    "apartment_floor": parse_float(row.get("apartment_floor")),
                }
            )
    return buckets


def impute_defaults(rows: list[dict]) -> dict[str, float]:
    def median_or(key: str, fallback: float) -> float:
        values = [row[key] for row in rows if row[key] is not None]
        return float(statistics.median(values)) if values else fallback

    return {
        "rooms": median_or("rooms", 2.0),
        "bedrooms": median_or("bedrooms", 1.0),
        "bathrooms": median_or("bathrooms", 1.0),
        "year": median_or("year", 2010.0),
        "building_floors": median_or("building_floors", 5.0),
        "apartment_floor": median_or("apartment_floor", 2.0),
    }


def feature_row(row: dict, defaults: dict[str, float], area: float | None = None) -> np.ndarray:
    area_value = float(area if area is not None else row["area"])

    def filled(key: str) -> tuple[float, float]:
        value = row.get(key)
        if value is None:
            return defaults[key], 1.0
        return float(value), 0.0

    rooms, rooms_m = filled("rooms")
    bedrooms, bedrooms_m = filled("bedrooms")
    bathrooms, bathrooms_m = filled("bathrooms")
    year, year_m = filled("year")
    building_floors, building_floors_m = filled("building_floors")
    apartment_floor, apartment_floor_m = filled("apartment_floor")

    return np.array(
        [
            1.0,
            area_value,
            math.log(max(area_value, 1.0)),
            rooms,
            rooms_m,
            bedrooms,
            bedrooms_m,
            bathrooms,
            bathrooms_m,
            year,
            year_m,
            building_floors,
            building_floors_m,
            apartment_floor,
            apartment_floor_m,
        ],
        dtype=np.float64,
    )


def design_matrix(rows: list[dict], defaults: dict[str, float]) -> np.ndarray:
    return np.vstack([feature_row(row, defaults) for row in rows])


def standardize_fit(x: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Z-score all columns except bias."""
    mean = x.mean(axis=0)
    std = x.std(axis=0)
    mean[0] = 0.0
    std[0] = 1.0
    std = np.where(std < 1e-8, 1.0, std)
    return (x - mean) / std, mean, std


def standardize_apply(x: np.ndarray, mean: np.ndarray, std: np.ndarray) -> np.ndarray:
    return (x - mean) / std


def fit_ridge(x: np.ndarray, y: np.ndarray, lambda_: float) -> np.ndarray:
    """Closed-form Ridge: argmin ||Xw - y||^2 + λ ||w_without_bias||^2."""
    n_features = x.shape[1]
    penalty = np.eye(n_features)
    penalty[0, 0] = 0.0  # do not shrink intercept
    xtx = x.T @ x + lambda_ * penalty
    xty = x.T @ y
    return np.linalg.solve(xtx, xty)


def predict_ppm2(x: np.ndarray, weights: np.ndarray) -> np.ndarray:
    return np.exp(x @ weights)


def mae(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.mean(np.abs(a - b)))


def rmse(a: np.ndarray, b: np.ndarray) -> float:
    return float(np.sqrt(np.mean((a - b) ** 2)))


def train_city(rows: list[dict], rng: np.random.Generator) -> CityResult | None:
    if len(rows) < MIN_MODEL_LISTINGS:
        return None

    index = np.arange(len(rows))
    rng.shuffle(index)
    split = max(1, int(round(len(rows) * (1 - TEST_FRACTION))))
    train_idx = index[:split]
    test_idx = index[split:]
    if len(test_idx) < 20:
        return None

    train_rows = [rows[i] for i in train_idx]
    test_rows = [rows[i] for i in test_idx]
    defaults = impute_defaults(train_rows)

    x_train_raw = design_matrix(train_rows, defaults)
    x_test_raw = design_matrix(test_rows, defaults)
    x_train, mean, std = standardize_fit(x_train_raw)
    x_test = standardize_apply(x_test_raw, mean, std)

    y_train = np.log(np.array([row["ppm2"] for row in train_rows], dtype=np.float64))
    y_test_ppm2 = np.array([row["ppm2"] for row in test_rows], dtype=np.float64)
    y_test_price = np.array([row["price"] for row in test_rows], dtype=np.float64)
    test_area = np.array([row["area"] for row in test_rows], dtype=np.float64)

    median_ppm2 = float(statistics.median(row["ppm2"] for row in train_rows))
    median_pred = np.full_like(y_test_ppm2, median_ppm2)

    # Choose λ on training fold by leave-10%-out of train (simple validation).
    n_train = len(train_rows)
    val_cut = max(1, int(round(n_train * 0.15)))
    x_fit, x_val = x_train[:-val_cut], x_train[-val_cut:]
    y_fit, y_val = y_train[:-val_cut], y_train[-val_cut:]
    y_val_ppm2 = np.exp(y_val)

    best_lambda = RIDGE_LAMBDAS[0]
    best_val_mae = float("inf")
    for lambda_ in RIDGE_LAMBDAS:
        weights = fit_ridge(x_fit, y_fit, lambda_)
        pred = predict_ppm2(x_val, weights)
        score = mae(pred, y_val_ppm2)
        if score < best_val_mae:
            best_val_mae = score
            best_lambda = lambda_

    weights = fit_ridge(x_train, y_train, best_lambda)
    model_pred = predict_ppm2(x_test, weights)

    median_mae_ppm2 = mae(median_pred, y_test_ppm2)
    model_mae_ppm2 = mae(model_pred, y_test_ppm2)
    median_rmse_ppm2 = rmse(median_pred, y_test_ppm2)
    model_rmse_ppm2 = rmse(model_pred, y_test_ppm2)

    median_price_pred = median_pred * test_area
    model_price_pred = model_pred * test_area
    median_mae_price = mae(median_price_pred, y_test_price)
    model_mae_price = mae(model_price_pred, y_test_price)

    # City-level 80 m² estimate: features from train listings near that size.
    near_80 = [row for row in train_rows if 60.0 <= row["area"] <= 100.0]
    profile_rows = near_80 if len(near_80) >= 20 else train_rows
    profile_defaults = impute_defaults(profile_rows)
    prototype = {
        "area": STANDARD_M2,
        "rooms": profile_defaults["rooms"],
        "bedrooms": profile_defaults["bedrooms"],
        "bathrooms": profile_defaults["bathrooms"],
        "year": profile_defaults["year"],
        "building_floors": profile_defaults["building_floors"],
        "apartment_floor": profile_defaults["apartment_floor"],
    }
    x80_raw = feature_row(prototype, defaults, area=STANDARD_M2).reshape(1, -1)
    x80 = standardize_apply(x80_raw, mean, std)
    model_ppm2_at_80 = float(predict_ppm2(x80, weights)[0])

    improvement = (median_mae_ppm2 - model_mae_ppm2) / median_mae_ppm2 * 100.0
    better = "model" if model_mae_ppm2 < median_mae_ppm2 else "median"
    if abs(improvement) < 1.0:
        better = "tie"

    return CityResult(
        city="",  # filled by caller
        country="",
        n_total=len(rows),
        n_train=len(train_rows),
        n_test=len(test_rows),
        lambda_=float(best_lambda),
        median_ppm2=round(median_ppm2, 1),
        model_ppm2_at_80=round(model_ppm2_at_80, 1),
        median_price_80=int(round(median_ppm2 * STANDARD_M2)),
        model_price_80=int(round(model_ppm2_at_80 * STANDARD_M2)),
        median_mae_ppm2=round(median_mae_ppm2, 1),
        model_mae_ppm2=round(model_mae_ppm2, 1),
        median_rmse_ppm2=round(median_rmse_ppm2, 1),
        model_rmse_ppm2=round(model_rmse_ppm2, 1),
        median_mae_price=round(median_mae_price, 0),
        model_mae_price=round(model_mae_price, 0),
        better_on_mae=better,
        mae_improvement_pct=round(improvement, 1),
    )


def evaluate_all() -> list[CityResult]:
    buckets = load_city_rows()
    results: list[CityResult] = []

    for country, (city_id, city_name, _) in CAPITALS.items():
        rows = buckets.get(country) or []
        if len(rows) < MIN_MODEL_LISTINGS:
            continue
        city_rng = np.random.default_rng(RANDOM_SEED + abs(hash(city_id)) % 10_000)
        result = train_city(rows, city_rng)
        if result is None:
            continue
        result.city = city_name
        result.country = country
        results.append(result)

    results.sort(key=lambda item: item.city)
    return results


def write_report(results: list[CityResult]) -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    payload = {
        "target": "log(USD per m²)",
        "loss": "mean squared error on log(USD/m²), with L2 Ridge penalty",
        "baseline": "train-set median USD/m²",
        "min_listings": MIN_MODEL_LISTINGS,
        "test_fraction": TEST_FRACTION,
        "standard_m2": STANDARD_M2,
        "features": FEATURE_NAMES,
        "cities": [asdict(item) for item in results],
    }
    OUT_JSON.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")

    lines = [
        "# Median vs regression (USD / m²)",
        "",
        "For each capital with at least "
        f"**{MIN_MODEL_LISTINGS}** city-filtered apartment listings, we train Ridge "
        "regression to predict `log(USD/m²)` from condo features (area, rooms, "
        "bedrooms, bathrooms, construction year, building floors, apartment floor, "
        "plus missingness flags). Training minimizes **MSE** on log price density "
        "plus an L2 penalty on weights. The baseline predicts the **train median** "
        "USD/m² for every listing.",
        "",
        "Held-out **MAE** on USD/m² is the main comparison. We also report an "
        f"**{int(STANDARD_M2)} m²** city-level estimate from both methods.",
        "",
        "| City | n | Median MAE $/m² | Model MAE $/m² | Δ MAE | Better | "
        f"Median {int(STANDARD_M2)} m² | Model {int(STANDARD_M2)} m² |",
        "| --- | ---: | ---: | ---: | ---: | --- | ---: | ---: |",
    ]
    for item in results:
        delta = item.median_mae_ppm2 - item.model_mae_ppm2
        lines.append(
            f"| {item.city} | {item.n_total} | "
            f"{item.median_mae_ppm2:,.0f} | {item.model_mae_ppm2:,.0f} | "
            f"{delta:+.0f} ({item.mae_improvement_pct:+.1f}%) | {item.better_on_mae} | "
            f"${item.median_price_80:,} | ${item.model_price_80:,} |"
        )

    wins = sum(1 for item in results if item.better_on_mae == "model")
    ties = sum(1 for item in results if item.better_on_mae == "tie")
    losses = sum(1 for item in results if item.better_on_mae == "median")
    lines.extend(
        [
            "",
            "## Takeaway",
            "",
            f"- Cities modeled: **{len(results)}** (need ≥ {MIN_MODEL_LISTINGS} listings).",
            f"- Model lower held-out MAE: **{wins}**; median lower: **{losses}**; "
            f"roughly tied (<1%): **{ties}**.",
            "- When features are informative (rooms, year, floors), regression can "
            "beat a flat median on listing-level error. The city headline for an "
            f"{int(STANDARD_M2)} m² condo can still stay close to the median, "
            "because that is already a strong pooled estimate.",
            "- Thin cities stay on the median method; a model there would overfit.",
            "",
        ]
    )
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")


def main() -> int:
    if not CSV_PATH.exists():
        raise FileNotFoundError(f"CSV not found: {CSV_PATH}")
    results = evaluate_all()
    write_report(results)
    print(f"Wrote {OUT_JSON}")
    print(f"Wrote {OUT_MD}")
    print()
    for item in results:
        print(
            f"{item.city:12} n={item.n_total:4}  "
            f"MAE median={item.median_mae_ppm2:7.1f}  "
            f"model={item.model_mae_ppm2:7.1f}  "
            f"({item.mae_improvement_pct:+5.1f}%)  "
            f"better={item.better_on_mae:6}  "
            f"80m² median=${item.median_price_80:,}  "
            f"model=${item.model_price_80:,}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
