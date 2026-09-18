#!/usr/bin/env python3
"""Attach per-city linear regression models to capitals.json for app inference."""

from __future__ import annotations

import csv
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

from build_capitals import (  # noqa: E402
    CAPITALS,
    CSV_PATH,
    MAX_AREA_M2,
    MIN_AREA_M2,
    is_apartment,
    location_is_city,
    parse_area,
    parse_price,
    title_of,
)
from price_model import MIN_MODEL_LISTINGS, train_city_model  # noqa: E402

OUT_PATH = ROOT / "app" / "assets" / "data" / "capitals.json"


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


def load_feature_rows() -> dict[str, list[dict]]:
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


def main() -> int:
    if not OUT_PATH.exists():
        raise FileNotFoundError(f"Run build_capitals.py first: {OUT_PATH}")
    payload = json.loads(OUT_PATH.read_text(encoding="utf-8"))
    buckets = load_feature_rows()
    trained = 0
    skipped = 0

    for city in payload["cities"]:
        country = city["country"]
        rows = buckets.get(country) or []
        model = train_city_model(rows)
        if model is None:
            city.pop("model", None)
            skipped += 1
            print(
                f"  skip  {city['city']:16} n={len(rows):4} "
                f"(need ≥ {MIN_MODEL_LISTINGS})"
            )
            continue
        city["model"] = model
        trained += 1
        print(f"  model {city['city']:16} n={model['n']:4}")

    payload["modelNote"] = (
        "Linear regression on log(USD/m²) from condo features, trained per city "
        f"when ≥ {MIN_MODEL_LISTINGS} listings. Compare screens show median and "
        "model estimates side by side."
    )
    OUT_PATH.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote models for {trained} cities ({skipped} median-only) → {OUT_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
