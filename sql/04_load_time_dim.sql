-- =============================================================================
-- 04_load_time_dim.sql
-- Populates TIME_DIM with one row per minute of the day (1,440 rows).
-- Safe to re-run.
-- =============================================================================

USE SCHEMA CHINOOK_DB.DW;

TRUNCATE TABLE TIME_DIM;

INSERT INTO TIME_DIM
SELECT
    (H * 100) + M                                         AS TIME_KEY,
    H                                                     AS HOUR_NUM,
    M                                                     AS MINUTE_NUM,
    LPAD(H::STRING, 2, '0') || ':' || LPAD(M::STRING, 2, '0') AS TIME_24_HR
FROM (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1 AS N
    FROM TABLE(GENERATOR(ROWCOUNT => 1440))
),
LATERAL (
    SELECT FLOOR(N / 60)::INT AS H, MOD(N, 60)::INT AS M
);
