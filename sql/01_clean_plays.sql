CREATE OR REPLACE TABLE workspace.badgers.plays_clean AS
WITH base AS (
  SELECT
    CAST(season AS INT)         AS season,
    CAST(week AS INT)           AS week,
    season_type,
    CAST(gameId AS BIGINT)      AS game_id,
    CAST(driveId AS BIGINT)     AS drive_id,
    CAST(period AS INT)         AS quarter,
    offense,
    defense,
    home,
    away,
    CAST(offenseScore AS INT)   AS offense_score,
    CAST(defenseScore AS INT)   AS defense_score,
    CAST(down AS INT)           AS down,
    CAST(distance AS INT)       AS distance,
    CAST(yardsToGoal AS INT)    AS yards_to_goal,
    CAST(yardsGained AS INT)    AS yards_gained,
    playType                    AS play_type,
    playText                    AS play_text,
    TRY_CAST(ppa AS DOUBLE)     AS ppa
  FROM workspace.badgers.plays_raw
),
cat AS (
  SELECT *,
    offense = 'Wisconsin' AS is_wisconsin_offense,
    CASE WHEN offense = 'Wisconsin' THEN defense ELSE offense END AS opponent,
    play_type IN ('Rushing Touchdown', 'Passing Touchdown') AS is_touchdown,
    CASE
      WHEN play_type IN ('Rush', 'Rushing Touchdown') THEN 'Run'
      WHEN play_type IN ('Pass Reception', 'Pass Incompletion', 'Pass Completion',
                         'Passing Touchdown', 'Interception',
                         'Pass Interception Return', 'Interception Return Touchdown',
                         'Sack') THEN 'Pass'
      ELSE 'Other'
    END AS play_category
  FROM base
)
SELECT *,
  down IN (3, 4) AND distance <= 3 AS is_short_yardage,
  yards_to_goal <= 20              AS is_red_zone,
  CASE WHEN play_category IN ('Run', 'Pass') THEN
    CASE
      WHEN is_touchdown THEN TRUE
      WHEN down = 1 THEN yards_gained >= 0.5 * distance
      WHEN down = 2 THEN yards_gained >= 0.7 * distance
      WHEN down IN (3, 4) THEN yards_gained >= distance
    END
  END AS is_success,
  CASE
    WHEN play_category = 'Run'  THEN yards_gained >= 10
    WHEN play_category = 'Pass' THEN yards_gained >= 20
  END AS is_explosive
FROM cat;
