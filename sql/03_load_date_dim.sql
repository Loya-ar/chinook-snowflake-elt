-- =============================================================================
-- 03_load_date_dim.sql
-- Populates DATE_DIM with one row per day from 2000-01-01 to 2030-12-31.
-- The range covers every Chinook release (invoice dates 2009-2013 in the
-- classic data set, 2021-2025 in newer ones), so no invoice is dropped by the
-- DATE_DIM join in 07_load_sales_fact.sql. Safe to re-run.
-- =============================================================================

USE SCHEMA CHINOOK_DB.DW;

TRUNCATE TABLE DATE_DIM;

INSERT INTO DATE_DIM
WITH seq AS (
    SELECT DATEADD(day, ROW_NUMBER() OVER (ORDER BY SEQ4()) - 1, '2000-01-01'::DATE) AS d
    FROM TABLE(GENERATOR(ROWCOUNT => 11323))   -- days in 2000-01-01 .. 2030-12-31
)
SELECT
    TO_NUMBER(TO_CHAR(d, 'YYYYMMDD'))      AS DATE_KEY,
    d                                      AS FULL_DATE,
    DAY(d)                                 AS DAY_NUM,
    MONTH(d)                               AS MONTH_NUM,
    YEAR(d)                                AS YEAR_NUM,
    TO_VARCHAR(d, 'DY')                    AS WEEKDAY_ABBR,
    IFF(DAYOFWEEKISO(d) IN (6, 7), 'Y', 'N') AS IS_WEEKEND
FROM seq;
