-- =============================================================================
-- 06_merge_customer_dim.sql
-- SQL alternative to the ADF data flow DF_Load_Customer_DIM: upserts
-- STAGE.CUSTOMER into DW.CUSTOMER_DIM (SCD Type 1). A row is updated only when
-- its CUSTOMER_HASH (SHA-256 of the tracked columns) changes.
-- Run this OR the data flow, not both.
-- =============================================================================

USE SCHEMA CHINOOK_DB.DW;

MERGE INTO CUSTOMER_DIM d
USING (
    SELECT
        CustomerId   AS CUSTOMER_ID,
        FirstName    AS FIRST_NAME,
        LastName     AS LAST_NAME,
        Company      AS COMPANY_NAME,
        City         AS CITY,
        State        AS STATE,
        Country      AS COUNTRY,
        PostalCode   AS ZIP_CODE,
        SupportRepId AS SUPPORT_REP_ID,
        'ADF'        AS SOURCE_ID,
        SHA2(CONCAT_WS('|',
            NVL(FirstName, ''), NVL(LastName, ''), NVL(Company, ''),
            NVL(City, ''), NVL(State, ''), NVL(Country, ''),
            NVL(PostalCode, ''), NVL(SupportRepId::STRING, '')
        ), 256)      AS CUSTOMER_HASH
    FROM CHINOOK_DB.STAGE.CUSTOMER
    QUALIFY ROW_NUMBER() OVER (PARTITION BY CustomerId ORDER BY CustomerId) = 1
) s
ON d.CUSTOMER_ID = s.CUSTOMER_ID
WHEN MATCHED AND NVL(d.CUSTOMER_HASH, '') <> s.CUSTOMER_HASH THEN
    UPDATE SET
        FIRST_NAME        = s.FIRST_NAME,
        LAST_NAME         = s.LAST_NAME,
        COMPANY_NAME      = s.COMPANY_NAME,
        CITY              = s.CITY,
        STATE             = s.STATE,
        COUNTRY           = s.COUNTRY,
        ZIP_CODE          = s.ZIP_CODE,
        SUPPORT_REP_ID    = s.SUPPORT_REP_ID,
        CUSTOMER_HASH     = s.CUSTOMER_HASH,
        DATE_TO_WAREHOUSE = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
    INSERT (CUSTOMER_KEY, CUSTOMER_ID, FIRST_NAME, LAST_NAME, COMPANY_NAME, CITY, STATE,
            COUNTRY, ZIP_CODE, SUPPORT_REP_ID, SOURCE_ID, CUSTOMER_HASH, DATE_TO_WAREHOUSE)
    VALUES (CUSTOMER_DIM_SEQ.NEXTVAL, s.CUSTOMER_ID, s.FIRST_NAME, s.LAST_NAME, s.COMPANY_NAME,
            s.CITY, s.STATE, s.COUNTRY, s.ZIP_CODE, s.SUPPORT_REP_ID, s.SOURCE_ID,
            s.CUSTOMER_HASH, CURRENT_TIMESTAMP());
