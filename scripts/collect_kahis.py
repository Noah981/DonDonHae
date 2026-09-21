#!/usr/bin/env python3
import datetime as dt
import hashlib
import html
import json
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

BASE = "https://home.kahis.go.kr/home/lkntscrinfo/selectLkntsOccrrncList.do"
OUT = Path("assets/data/disease-alerts.json")
TARGETS = {
    "아프리카돼지열병": "ASF",
    "구제역": "구제역",
    "돼지생식기호흡기 증후군": "PRRS",
    "돼지생식기호흡기증후군": "PRRS",
}

PROVINCES = [
    "서울특별시", "부산광역시", "대구광역시", "인천광역시", "광주광역시",
    "대전광역시", "울산광역시", "세종특별자치시", "경기도", "강원특별자치도",
    "강원도", "충청북도", "충청남도", "전북특별자치도", "전라북도",
    "전라남도", "경상북도", "경상남도", "제주특별자치도",
    "전남광주통합특별시",
]

def text_only(raw):
    raw = re.sub(r"<script[\s\S]*?</script>", " ", raw, flags=re.I)
    raw = re.sub(r"<style[\s\S]*?</style>", " ", raw, flags=re.I)
    raw = re.sub(r"<[^>]+>", " ", raw)
    return re.sub(r"\s+", " ", html.unescape(raw)).strip()

def split_address(address):
    province = ""
    for candidate in PROVINCES:
        if address.startswith(candidate):
            province = candidate
            break
    remainder = address[len(province):].strip() if province else address
    tokens = remainder.split()
    city = tokens[0] if tokens else ""
    if city.endswith(("시", "군", "구")) and len(tokens) > 1 and tokens[1].endswith("구"):
        city = city + " " + tokens[1]
    return province, city

def parse_date(value):
    m = re.search(r"(20\d{2})[-./](\d{1,2})[-./](\d{1,2})", value)
    if not m:
        return None
    return f"{int(m.group(1)):04d}-{int(m.group(2)):02d}-{int(m.group(3)):02d}"

def fetch(page):
    query = urllib.parse.urlencode({"openFlag": "Y", "pageIndex": page})
    req = urllib.request.Request(
        BASE + "?" + query,
        headers={"User-Agent": "DonDonHae/1.0 (+official-outbreak-sync)"},
    )
    with urllib.request.urlopen(req, timeout=20) as response:
        return response.read().decode("utf-8", errors="ignore")

def row_cells(page_html):
    for row in re.findall(r"<tr[^>]*>([\s\S]*?)</tr>", page_html, flags=re.I):
        cells = [
            text_only(cell)
            for cell in re.findall(r"<td[^>]*>([\s\S]*?)</td>", row, flags=re.I)
        ]
        if cells:
            yield cells

def to_event(cells):
    joined = " | ".join(cells)
    disease_name = next((name for name in TARGETS if name in joined), None)
    if not disease_name:
        return None

    disease = TARGETS[disease_name]
    address = next(
        (cell for cell in cells if any(cell.startswith(p) for p in PROVINCES)),
        "",
    )
    if not address:
        return None

    date = next((parse_date(cell) for cell in cells if parse_date(cell)), None)
    province, city = split_address(address)
    livestock = next((cell for cell in cells if "돼지" in cell or "소" in cell), "")
    key = "|".join([disease, address, date or "", livestock])
    event_id = "KAHIS-" + hashlib.sha1(key.encode("utf-8")).hexdigest()[:16].upper()

    return {
        "id": event_id,
        "diseaseType": disease,
        "countryCode": "KR",
        "province": province,
        "cityCounty": city,
        "districtCode": "",
        "latitude": None,
        "longitude": None,
        "occurrenceDate": date,
        "announcementDate": date,
        "livestockType": livestock or "확인 필요",
        "status": "발생",
        "source": "국가가축방역통합시스템(KAHIS)",
        "sourceUrl": BASE,
        "verificationLevel": "official_region_only",
        "summary": "KAHIS 법정가축전염병 발생현황에서 공식 확인된 발생 건입니다.",
    }

def main():
    collected = {}
    empty_pages = 0
    previous_fingerprint = None
    for page in range(1, 81):
        try:
            body = fetch(page)
        except Exception as exc:
            print(f"KAHIS fetch page {page} failed: {exc}", file=sys.stderr)
            break

        fingerprint = hashlib.sha1(body.encode('utf-8')).hexdigest()
        if fingerprint == previous_fingerprint:
            print('KAHIS pagination returned the same page; stopping safely.')
            break
        previous_fingerprint = fingerprint

        found_any_row = False
        for cells in row_cells(body):
            found_any_row = True
            event = to_event(cells)
            if event:
                collected[event["id"]] = event

        if not found_any_row:
            empty_pages += 1
            if empty_pages >= 2:
                break
        else:
            empty_pages = 0

    if not collected:
        print("No target KAHIS rows parsed; preserving bundled snapshot.")
        return 0

    now = dt.datetime.now(dt.timezone(dt.timedelta(hours=9))).isoformat()
    payload = {
        "schemaVersion": 3,
        "updatedAt": now,
        "notice": (
            "KAHIS 공식 공개 발생정보 자동 수집본입니다. "
            "PED 등 공식 공개 발생자료가 확보되지 않은 질병은 0건으로 단정하지 않습니다."
        ),
        "items": sorted(
            collected.values(),
            key=lambda x: x.get("occurrenceDate") or "",
            reverse=True,
        ),
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(collected)} official KAHIS events.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
