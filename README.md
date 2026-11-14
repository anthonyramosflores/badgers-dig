# Dig Into the Badgers

**MadHacks 2026 · Databricks track · theme: "Let's dig in"**

Ask Wisconsin football's play-by-play data questions in plain English. We dig through five seasons of Badgers plays (2021-2025) with a Databricks Genie agent and an AI/BI dashboard, both sitting on a bronze → silver → gold data pipeline.

> "What's Wisconsin's success rate on 3rd and short?" → *62.8% (150 of 239 plays, 2021-2025).*

## What it does
- **Genie agent:** fans and coaches ask questions like "How did our run rate change from 2022 to 2023?" and get answers backed by SQL.
- **Dashboard:** run rate, success rate and explosive rate by season; success rate by down and distance; and Badgers offense vs. defense.
- **The "dig" in both senses:** we dig through layers of data (bronze → silver → gold) to dig into what the team does on the field.

![Dashboard](docs/dashboard.png)

## Architecture
```
CollegeFootballData API ──► CSV (pull.py) ──► Databricks Unity Catalog
                                              │
  bronze: workspace.badgers.plays_raw         │  raw plays, as pulled
  silver: workspace.badgers.plays_clean       │  typed, flagged, run/pass classified
  gold:   gold_team_season, gold_situational  │  small summary tables for serving
                                              ▼
                              Genie agent  +  AI/BI dashboard
```

| Layer | Table | What it holds |
|---|---|---|
| Bronze | `plays_raw` | ~10.5k plays from Wisconsin games, exactly as the API returned them |
| Silver | `plays_clean` | Clean types, `is_wisconsin_offense`, `play_category` (Run/Pass/Other), `is_success`, `is_explosive`, `is_red_zone`, `is_short_yardage` |
| Gold | `gold_team_season`, `gold_situational` | Rates by season and by down/distance, which feed the dashboard |

### Metric definitions
- **Success rate:** a run or pass play succeeds if it gains 50% of the needed yards on 1st down, 70% on 2nd down, or 100% on 3rd/4th down, or scores a touchdown.
- **Explosive play:** a run of 10+ yards or a pass of 20+ yards.
- **Sacks** count as pass plays. Punts, kickoffs, penalties and similar plays are "Other" and excluded from rates.

## Databricks features used
- Unity Catalog tables and schemas (Free Edition)
- Serverless SQL warehouse and SQL for the bronze → silver → gold transformations
- Genie agent with custom instructions, measures and example questions
- AI/BI dashboard built on SQL datasets from the gold tables
- Genie Code / the Databricks assistant to help build the dashboard and agent

## Repo contents
| Path | Purpose |
|---|---|
| `pull.py` | Pulls Wisconsin play-by-play for 2021-2025 from the CFBD API into a CSV |
| `sql/01_clean_plays.sql` | Builds the silver table `plays_clean` |
| `sql/02_gold_tables.sql` | Builds the gold summary tables |
| `genie/instructions.md` | The Genie agent's instructions and metric definitions |
| `docs/` | Screenshots |

## Reproduce it
1. Get a free API key from [collegefootballdata.com](https://collegefootballdata.com).
2. Pull the data:
   ```bash
   python3 -m venv .venv && source .venv/bin/activate
   pip install requests pandas
   export CFBD_KEY="your-key"
   python pull.py          # writes wisconsin_plays.csv
   ```
3. In Databricks (Free Edition), create the schema `workspace.badgers`, then upload `wisconsin_plays.csv` as the table `plays_raw`.
4. Run `sql/01_clean_plays.sql`, then `sql/02_gold_tables.sql`.
5. Create a Genie agent on `workspace.badgers.plays_clean` and paste in `genie/instructions.md`.
6. Build the dashboard from the gold tables.

## Notes and limitations
- Covers five complete seasons (2021-2025). The 2026 season is not included.
- Postseason games appear only for 2021-2023 in the data.
- Data comes from [CollegeFootballData.com](https://collegefootballdata.com). Check their terms before reusing it.
- Free Edition has daily compute quotas, so everything here is kept small on purpose.

## What I learned
Built solo, as my first project on Databricks. The biggest lessons: how Unity Catalog organizes tables, how much a Genie agent depends on clear instructions and metric definitions, and how useful it is to check the agent's answers against your own SQL
.
