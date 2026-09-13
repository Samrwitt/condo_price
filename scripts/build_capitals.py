#!/usr/bin/env python3
"""Build a compact capitals.json from the world real-estate listings CSV."""

from __future__ import annotations

import csv
import json
import math
import re
import statistics
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CSV_PATH = ROOT / "world_real_estate_data(147k).csv"
OUT_PATH = ROOT / "app" / "assets" / "data" / "capitals.json"

MIN_AREA_M2 = 15.0
MAX_AREA_M2 = 400.0
MIN_LISTINGS = 30
STANDARD_M2 = 80.0

HOUSE_WORDS = (
    "villa",
    "house",
    "cottage",
    "townhouse",
    "chalet",
    "mansion",
)
APARTMENT_WORDS = (
    "apartment",
    "studio",
    "penthouse",
    "condo",
    "flat",
    "loft",
)

# Country -> (id, city, aliases). Aliases are matched as whole tokens in
# location + title so regional labels like "Central Hungary" are not used.
CAPITALS = {
    "Turkey": ("ankara", "Ankara", ("ankara",)),
    "Hungary": ("budapest", "Budapest", ("budapest",)),
    "Russia": ("moscow", "Moscow", ("moscow", "moskva")),
    "Spain": ("madrid", "Madrid", ("madrid",)),
    "Belarus": ("minsk", "Minsk", ("minsk",)),
    "Greece": ("athens", "Athens", ("athens", "athina")),
    "Montenegro": ("podgorica", "Podgorica", ("podgorica",)),
    "Italy": ("rome", "Rome", ("rome", "roma")),
    "Georgia": ("tbilisi", "Tbilisi", ("tbilisi",)),
    "UAE": ("abu-dhabi", "Abu Dhabi", ("abu dhabi",)),
    "Lithuania": ("vilnius", "Vilnius", ("vilnius",)),
    "Latvia": ("riga", "Riga", ("riga",)),
    "Thailand": ("bangkok", "Bangkok", ("bangkok",)),
    "Portugal": ("lisbon", "Lisbon", ("lisbon", "lisboa")),
    "Croatia": ("zagreb", "Zagreb", ("zagreb",)),
    "Uzbekistan": ("tashkent", "Tashkent", ("tashkent",)),
    "Finland": ("helsinki", "Helsinki", ("helsinki",)),
    "Czech Republic": ("prague", "Prague", ("prague", "praha")),
    "Poland": ("warsaw", "Warsaw", ("warsaw", "warszawa")),
    "Austria": ("vienna", "Vienna", ("vienna", "wien")),
    "Armenia": ("yerevan", "Yerevan", ("yerevan",)),
    "Serbia": ("belgrade", "Belgrade", ("belgrade", "beograd")),
    "Northern Cyprus": ("north-nicosia", "North Nicosia", ("north nicosia", "lefkosa", "lefkoşa")),
    "Cyprus": ("nicosia", "Nicosia", ("nicosia", "lefkosia")),
    "Indonesia": ("jakarta", "Jakarta", ("jakarta",)),
    "Australia": ("canberra", "Canberra", ("canberra",)),
}

AREA_RE = re.compile(r"([\d]+(?:[.,]\d+)?)")
TOKEN_RE = re.compile(r"[a-z0-9ş]+")


def title_of(row: dict, title_key: str) -> str:
    return row.get("title") or row.get(title_key) or ""


def parse_area(value: str | None) -> float | None:
    if not value:
        return None
    match = AREA_RE.search(value.replace(" ", ""))
    if not match:
        return None
    try:
        area = float(match.group(1).replace(",", "."))
    except ValueError:
        return None
    if area <= 0:
        return None
    return area


def parse_price(value: str | None) -> float | None:
    if not value:
        return None
    try:
        price = float(value)
    except ValueError:
        return None
    if price <= 0 or math.isnan(price):
        return None
    return price


def is_apartment(title: str) -> bool:
    lowered = title.lower()
    if any(word in lowered for word in HOUSE_WORDS):
        return False
    return any(word in lowered for word in APARTMENT_WORDS)


def blob_matches(blob: str, aliases: tuple[str, ...]) -> bool:
    tokens = set(TOKEN_RE.findall(blob))
    for alias in aliases:
        parts = alias.split()
        if len(parts) == 1:
            if parts[0] in tokens:
                return True
        elif all(part in tokens for part in parts):
            return True
    return False


def percentile(sorted_values: list[float], pct: float) -> float:
    if not sorted_values:
        raise ValueError("empty series")
    if len(sorted_values) == 1:
        return sorted_values[0]
    index = (len(sorted_values) - 1) * pct
    lo = math.floor(index)
    hi = math.ceil(index)
    if lo == hi:
        return sorted_values[lo]
    weight = index - lo
    return sorted_values[lo] * (1 - weight) + sorted_values[hi] * weight


def build() -> list[dict]:
    if not CSV_PATH.exists():
        raise FileNotFoundError(f"CSV not found: {CSV_PATH}")

    with CSV_PATH.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            raise ValueError("CSV has no header")
        title_key = reader.fieldnames[0]
        buckets: dict[str, list[float]] = {country: [] for country in CAPITALS}

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
            blob = f"{row.get('location') or ''} {title}".lower()
            _, _, aliases = CAPITALS[country]
            if not blob_matches(blob, aliases):
                continue
            buckets[country].append(price / area)

    records = []
    for country, (city_id, city, _) in CAPITALS.items():
        values = buckets[country]
        if len(values) < MIN_LISTINGS:
            continue
        values.sort()
        median = statistics.median(values)
        records.append(
            {
                "id": city_id,
                "city": city,
                "country": country,
                "listingCount": len(values),
                "medianUsdPerM2": round(median, 1),
                "p25UsdPerM2": round(percentile(values, 0.25), 1),
                "p75UsdPerM2": round(percentile(values, 0.75), 1),
                "price80m2": int(round(median * STANDARD_M2)),
            }
        )

    records.sort(key=lambda item: item["city"])
    return records


def main() -> int:
    records = build()
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "standardM2": STANDARD_M2,
        "source": CSV_PATH.name,
        "cities": records,
    }
    OUT_PATH.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(records)} capitals to {OUT_PATH}")
    for record in records:
        print(
            f"  {record['city']:16} {record['country']:18} "
            f"n={record['listingCount']:4}  "
            f"${record['medianUsdPerM2']:,.0f}/m²  "
            f"80m²=${record['price80m2']:,}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
