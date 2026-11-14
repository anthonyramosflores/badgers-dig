CREATE OR REPLACE TABLE workspace.badgers.gold_team_season AS
SELECT season, is_wisconsin_offense,
       count(*) AS plays,
       sum(CASE WHEN play_category = 'Run' THEN 1 ELSE 0 END)  AS runs,
       sum(CASE WHEN play_category = 'Pass' THEN 1 ELSE 0 END) AS passes,
       round(avg(CASE WHEN play_category = 'Run' THEN 1.0 ELSE 0.0 END), 3) AS run_rate,
       round(avg(CASE WHEN is_success THEN 1.0 ELSE 0.0 END), 3)            AS success_rate,
       round(avg(CASE WHEN is_explosive THEN 1.0 ELSE 0.0 END), 3)          AS explosive_rate,
       round(avg(yards_gained), 2) AS yards_per_play,
       round(avg(ppa), 3)          AS avg_ppa
FROM workspace.badgers.plays_clean
WHERE play_category IN ('Run', 'Pass')
GROUP BY season, is_wisconsin_offense;

CREATE OR REPLACE TABLE workspace.badgers.gold_situational AS
SELECT season, is_wisconsin_offense, down,
       CASE WHEN distance <= 3 THEN '1 short (1-3)'
            WHEN distance <= 7 THEN '2 medium (4-7)'
            ELSE '3 long (8+)' END AS distance_bucket,
       count(*) AS plays,
       round(avg(CASE WHEN play_category = 'Run' THEN 1.0 ELSE 0.0 END), 3) AS run_rate,
       round(avg(CASE WHEN is_success THEN 1.0 ELSE 0.0 END), 3)            AS success_rate,
       round(avg(yards_gained), 2) AS yards_per_play
FROM workspace.badgers.plays_clean
WHERE play_category IN ('Run', 'Pass') AND down BETWEEN 1 AND 4
GROUP BY season, is_wisconsin_offense, down,
         CASE WHEN distance <= 3 THEN '1 short (1-3)'
              WHEN distance <= 7 THEN '2 medium (4-7)'
              ELSE '3 long (8+)' END;
