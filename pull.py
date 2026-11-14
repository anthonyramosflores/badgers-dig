"""Pull Wisconsin play-by-play from the CollegeFootballData (CFBD) API into one CSV.

Usage:
    export CFBD_KEY=...   # read only from the environment, never stored in files
    python pull.py

Notes:
  * /plays REQUIRES `year` and `week`, so we make one call per (season, week).
    That is 15 regular-season weeks + 1 postseason call per season = 80 calls total.
  * Each successful response is cached in .cache/ so re-running costs 0 API calls.
    Delete .cache/ to force a fresh pull.
  * team=Wisconsin matches plays where Wisconsin is on EITHER side of the ball,
    so the CSV includes opponent offense too (use `offense` to tell them apart).
"""
import json
import os
import sys
import time
from pathlib import Path

import pandas as pd
import requests

URL = "https://api.collegefootballdata.com/plays"
TEAM = "Wisconsin"
SEASONS = range(2021, 2026)          # 2021..2025
REGULAR_WEEKS = range(1, 16)         # weeks 1..15 (bye weeks simply return [])
OUT_CSV = "wisconsin_plays.csv"
CACHE_DIR = Path(".cache")


def fetch(session, params, key):
    """Return a list of plays for one request, using the disk cache when possible.

    Returns None if we should abort the whole run (bad key / rate limit).
    """
    cache_file = CACHE_DIR / "{year}_{seasonType}_{week}.json".format(**params)
    if cache_file.exists():
        return json.loads(cache_file.read_text()), "cache"

    for attempt in (1, 2):  # one retry for transient server errors
        try:
            resp = session.get(URL, params=params, timeout=60)
        except requests.RequestException as exc:
            print("    network error: %s" % exc)
            if attempt == 1:
                time.sleep(2)
                continue
            return [], "error"

        if resp.status_code == 200:
            data = resp.json()
            CACHE_DIR.mkdir(exist_ok=True)
            cache_file.write_text(json.dumps(data))
            return data, "api"
        if resp.status_code in (401, 403):
            sys.exit("Auth failed (%d). Check that CFBD_KEY is a valid key." % resp.status_code)
        if resp.status_code == 429:
            sys.exit("Rate/monthly limit hit (429). Re-run later; cached weeks are kept.")
        if resp.status_code >= 500 and attempt == 1:
            time.sleep(2)
            continue
        print("    HTTP %d: %s" % (resp.status_code, resp.text[:120]))
        return [], "error"
    return [], "error"


def main():
    key = os.environ.get("CFBD_KEY")
    if not key:
        sys.exit("CFBD_KEY environment variable is not set.")

    session = requests.Session()
    session.headers["Authorization"] = "Bearer " + key
    session.headers["Accept"] = "application/json"

    frames, api_calls = [], 0
    for season in SEASONS:
        # (seasonType, week) combos: 15 regular weeks, then 1 postseason call
        combos = [("regular", w) for w in REGULAR_WEEKS] + [("postseason", 1)]
        for season_type, week in combos:
            params = {"year": season, "week": week, "team": TEAM, "seasonType": season_type}
            data, source = fetch(session, params, key)
            if source == "api":
                api_calls += 1
            label = "%d %-10s wk %2d" % (season, season_type, week)
            if not data:
                print("%s -> no plays (%s)" % (label, source))
                continue
            df = pd.json_normalize(data)          # flattens clock.minutes / clock.seconds
            df["season"] = season
            df["week"] = week
            df["season_type"] = season_type
            frames.append(df)
            print("%s -> %5d plays (%s)" % (label, len(df), source))

    if not frames:
        sys.exit("No data pulled.")
    out = pd.concat(frames, ignore_index=True)
    out.to_csv(OUT_CSV, index=False)
    print("\nWrote %s: %d rows, %d columns. API calls made this run: %d"
          % (OUT_CSV, len(out), out.shape[1], api_calls))


if __name__ == "__main__":
    main()
