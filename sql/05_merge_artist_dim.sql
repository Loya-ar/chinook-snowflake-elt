-- =============================================================================
-- 05_merge_artist_dim.sql
-- Upserts STAGE.ARTIST into DW.ARTIST_DIM (SCD Type 1).
-- The source is de-duplicated on ArtistId, so landing the same Parquet files
-- into STAGE more than once does not create duplicate dimension rows.
-- =============================================================================

USE SCHEMA CHINOOK_DB.DW;

MERGE INTO ARTIST_DIM d
USING (
    SELECT
        ArtistId AS ARTIST_ID,
        Name     AS ARTIST_NAME,
        'ADF'    AS SOURCE_ID
    FROM CHINOOK_DB.STAGE.ARTIST
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ArtistId ORDER BY ArtistId) = 1
) s
ON d.ARTIST_ID = s.ARTIST_ID
WHEN MATCHED AND NVL(d.ARTIST_NAME, '') <> NVL(s.ARTIST_NAME, '') THEN
    UPDATE SET
        ARTIST_NAME       = s.ARTIST_NAME,
        DATE_TO_WAREHOUSE = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
    INSERT (ARTIST_KEY, ARTIST_ID, ARTIST_NAME, SOURCE_ID, DATE_TO_WAREHOUSE)
    VALUES (ARTIST_DIM_SEQ.NEXTVAL, s.ARTIST_ID, s.ARTIST_NAME, s.SOURCE_ID, CURRENT_TIMESTAMP());
