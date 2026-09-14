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
INDICATIVE_BELOW = 200
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

# Country -> (id, city, aliases). Matching uses location parts, not title, so
# a name in "Minsk Region" is not treated as the city of Minsk.
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
ADMIN_MARKERS = {
    "region",
    "district",
    "county",
    "province",
    "oblast",
    "prefecture",
    "emirate",
    "metropolitan",
    "greater",
    "voivodeship",
    "governorate",
    "krai",
    "canton",
    "department",
    "raion",
    "okrug",
    "area",
    "savivaldybe",
    "rajono",
    "subregion",
}
CITY_EXTRA = {
    "city",
    "of",
    "the",
    "municipality",
    "capital",
    "capitale",
    "community",
    "grad",
    "urban",
    "de",
    "di",
    "bei",
}
# Large containing areas. Not towns, and not "Transdanubia" / "Abkhazia"
# which tag listings that are not in the capital.
BROAD_MARKERS = {
    "central",
    "mainland",
    "southern",
    "northern",
    "eastern",
    "western",
    "federal",
    "attica",
    "lazio",
    "anatolia",
    "vidzeme",
    "masovian",
}

COVERAGE = (
    "Median condo prices for the 22 capitals in this listing set. "
    "London, Paris, Tokyo and New York are not in the source data."
)
METHOD = (
    "Median USD per m² from apartment listings in the city itself, "
    f"not the surrounding region. Cities with fewer than {INDICATIVE_BELOW} "
    "listings are marked indicative."
)


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


def tokens(text: str) -> list[str]:
    normalized = (
        text.lower()
        .replace("sub-region", "subregion")
        .replace("sub region", "subregion")
    )
    return TOKEN_RE.findall(normalized)


def alias_parts(alias: str) -> list[str]:
    return alias.split()


def matches_alias(toks: list[str], aliases: tuple[str, ...]) -> bool:
    token_set = set(toks)
    for alias in aliases:
        parts = alias_parts(alias)
        if all(part in token_set for part in parts):
            return True
    return False


def core_tokens(toks: list[str]) -> list[str]:
    return [token for token in toks if token not in CITY_EXTRA]


def has_admin_marker(toks: list[str]) -> bool:
    return any(token in ADMIN_MARKERS for token in toks)


def is_exact_city(part: str, aliases: tuple[str, ...]) -> bool:
    toks = tokens(part)
    if has_admin_marker(toks):
        return False
    core = core_tokens(toks)
    return any(core == alias_parts(alias) for alias in aliases)


def is_admin_city(part: str, aliases: tuple[str, ...]) -> bool:
    toks = tokens(part)
    return has_admin_marker(toks) and matches_alias(toks, aliases)


def is_broad(part: str, aliases: tuple[str, ...]) -> bool:
    if is_exact_city(part, aliases):
        return False
    toks = tokens(part)
    if has_admin_marker(toks):
        return True
    return any(token in BROAD_MARKERS for token in toks)


def classify_part(part: str, aliases: tuple[str, ...]) -> str:
    if is_exact_city(part, aliases):
        return "city"
    if is_admin_city(part, aliases):
        return "admin"
    if is_broad(part, aliases):
        return "broad"
    return "place"


def location_parts(location: str, country: str) -> list[str]:
    parts = [part.strip() for part in location.split(",") if part.strip()]
    if parts and parts[-1].lower() == country.lower():
        parts = parts[:-1]
    return parts


def location_is_city(location: str, country: str, aliases: tuple[str, ...]) -> bool:
    """Keep the city itself; drop region, county, and neighboring towns."""
    parts = location_parts(location, country)
    if not parts:
        return False
    kinds = [classify_part(part, aliases) for part in parts]
    first = kinds[0]
    has_city = "city" in kinds
    has_place = "place" in kinds
    if first == "city":
        return True
    if has_city and first in {"broad", "admin"}:
        return True
    # Helsinki-style rows name only a sub-region, under a broad country label.
    if first == "broad" and not has_place and not has_city:
        return any(is_admin_city(part, aliases) for part in parts)
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


def assert_location_examples() -> None:
    cases = [
        ("Minsk, Belarus", "Belarus", ("minsk",), True),
        ("Minsk Region, Minsk District, Belarus", "Belarus", ("minsk",), False),
        ("Kopisca, Minsk Region, Minsk District, Belarus", "Belarus", ("minsk",), False),
        ("Central Hungary, Budapest, Komarom-Esztergom, Hungary", "Hungary", ("budapest",), True),
        ("Transdanubia, Budapest, Komarom-Esztergom, Hungary", "Hungary", ("budapest",), False),
        ("Budapest, Central Hungary, Hungary", "Hungary", ("budapest",), True),
        ("Lazio, Rome, Roma Capitale, Italy", "Italy", ("rome", "roma"), True),
        ("Anzio, Lazio, Roma Capitale, Italy", "Italy", ("rome", "roma"), False),
        ("Community of Madrid, Area metropolitana de Madrid y Corredor del Henares, Spain", "Spain", ("madrid",), True),
        ("San Sebastian de los Reyes, Community of Madrid, Area metropolitana de Madrid y Corredor del Henares, Spain", "Spain", ("madrid",), False),
        ("Mainland Finland, Helsinki sub-region, Southern Finland, Finland", "Finland", ("helsinki",), True),
        ("Jaervenpaeae, Mainland Finland, Helsinki sub-region, Southern Finland, Finland", "Finland", ("helsinki",), False),
        ("Vilnius County, Vilnius, Vilnius city municipality, Lithuania", "Lithuania", ("vilnius",), True),
        ("Rokantiskes, Vilnius County, Vilniaus rajono savivaldybe, Lithuania", "Lithuania", ("vilnius",), False),
        ("Tbilisi, Georgia", "Georgia", ("tbilisi",), True),
        ("Abkhazia, Tbilisi, Georgia", "Georgia", ("tbilisi",), False),
        ("Vienna, Austria", "Austria", ("vienna", "wien"), True),
        ("Gerasdorf bei Wien, Lower Austria, Austria", "Austria", ("vienna", "wien"), False),
        ("Zagreb, Croatia", "Croatia", ("zagreb",), True),
        ("Samobor, Zagreb County, Croatia", "Croatia", ("zagreb",), False),
        ("Attica, Municipality of Athens, Regional Unit of Central Athens, Greece", "Greece", ("athens", "athina"), True),
        ("Rafina, Attica, Municipality of Athens, Greece", "Greece", ("athens", "athina"), False),
        ("Abu Dhabi Emirate, Abu Dhabi, UAE", "UAE", ("abu dhabi",), True),
        ("Masovian Voivodeship, Warsaw, Poland", "Poland", ("warsaw", "warszawa"), True),
        ("Lomianki, Masovian Voivodeship, Warsaw West County, Poland", "Poland", ("warsaw", "warszawa"), False),
    ]
    for location, country, aliases, expected in cases:
        got = location_is_city(location, country, aliases)
        if got != expected:
            raise AssertionError(
                f"{location!r}: expected {expected}, got {got}"
            )


PHOTOS_PER_CITY = 4


def pick_photos(listings: list[dict], median: float, limit: int = PHOTOS_PER_CITY) -> list[str]:
    """Prefer photos from listings closest to the city median price/m²."""
    ranked = sorted(listings, key=lambda item: abs(item["ppm2"] - median))
    photos: list[str] = []
    seen: set[str] = set()
    for item in ranked:
        url = item["image"]
        if not url or url in seen:
            continue
        photos.append(url)
        seen.add(url)
        if len(photos) >= limit:
            break
    return photos


def build() -> list[dict]:
    if not CSV_PATH.exists():
        raise FileNotFoundError(f"CSV not found: {CSV_PATH}")

    with CSV_PATH.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames:
            raise ValueError("CSV has no header")
        title_key = reader.fieldnames[0]
        buckets: dict[str, list[dict]] = {country: [] for country in CAPITALS}

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
            image = (row.get("image") or "").strip()
            buckets[country].append(
                {
                    "ppm2": price / area,
                    "image": image,
                }
            )

    records = []
    for country, (city_id, city, _) in CAPITALS.items():
        listings = buckets[country]
        if len(listings) < MIN_LISTINGS:
            continue
        values = sorted(item["ppm2"] for item in listings)
        median = statistics.median(values)
        listing_count = len(values)
        records.append(
            {
                "id": city_id,
                "city": city,
                "country": country,
                "listingCount": listing_count,
                "indicative": listing_count < INDICATIVE_BELOW,
                "medianUsdPerM2": round(median, 1),
                "p25UsdPerM2": round(percentile(values, 0.25), 1),
                "p75UsdPerM2": round(percentile(values, 0.75), 1),
                "price80m2": int(round(median * STANDARD_M2)),
                "photos": pick_photos(listings, median),
            }
        )

    records.sort(key=lambda item: item["city"])
    return records


def main() -> int:
    assert_location_examples()
    records = build()
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "standardM2": STANDARD_M2,
        "source": CSV_PATH.name,
        "indicativeBelow": INDICATIVE_BELOW,
        "coverage": COVERAGE,
        "method": METHOD,
        "cities": records,
    }
    OUT_PATH.write_text(
        json.dumps(payload, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(records)} capitals to {OUT_PATH}")
    for record in records:
        flag = " indicative" if record["indicative"] else ""
        print(
            f"  {record['city']:16} {record['country']:18} "
            f"n={record['listingCount']:4}  "
            f"photos={len(record['photos'])}  "
            f"${record['medianUsdPerM2']:,.0f}/m²  "
            f"80m²=${record['price80m2']:,}{flag}"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
