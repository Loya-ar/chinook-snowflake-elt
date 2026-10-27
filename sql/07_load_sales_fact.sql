-- =============================================================================
-- 07_load_sales_fact.sql
-- Loads one SALES_FACT row per invoice, resolving CUSTOMER_KEY from
-- CUSTOMER_DIM and DATE_DIM_KEY from DATE_DIM. MERGE on INVOICE_ID makes the
-- load safe to re-run: existing invoices are refreshed, new ones are inserted.
-- =============================================================================

USE SCHEMA CHINOOK_DB.DW;

MERGE INTO SALES_FACT f
USING (
    WITH TMP_INVOICE AS (
        SELECT
            i.InvoiceId                                         AS INVOICE_ID,
            i.CustomerId                                        AS CUSTOMER_ID,
            TO_NUMBER(TO_CHAR(CAST(i.InvoiceDate AS DATE), 'YYYYMMDD')) AS DATE_KEY,
            i.Total                                             AS TOTAL_SALE_AMT,
            1                                                   AS SOURCE_ID
        FROM CHINOOK_DB.STAGE.INVOICE i
        QUALIFY ROW_NUMBER() OVER (PARTITION BY i.InvoiceId ORDER BY i.InvoiceId) = 1
    ),
    CUSTOMER_LOOKUP AS (
        SELECT CUSTOMER_ID, CUSTOMER_KEY
        FROM DW.CUSTOMER_DIM
        QUALIFY ROW_NUMBER() OVER (PARTITION BY CUSTOMER_ID ORDER BY DATE_TO_WAREHOUSE DESC) = 1
    )
    SELECT
        c.CUSTOMER_KEY,
        x.INVOICE_ID,
        d.DATE_KEY,
        x.TOTAL_SALE_AMT,
        x.SOURCE_ID
    FROM TMP_INVOICE x
    JOIN DW.DATE_DIM d     ON d.DATE_KEY = x.DATE_KEY
    JOIN CUSTOMER_LOOKUP c ON c.CUSTOMER_ID = x.CUSTOMER_ID
) s
ON f.INVOICE_ID = s.INVOICE_ID
WHEN MATCHED THEN
    UPDATE SET
        CUSTOMER_KEY      = s.CUSTOMER_KEY,
        DATE_DIM_KEY      = s.DATE_KEY,
        TOTAL_SALE_AMT    = s.TOTAL_SALE_AMT,
        DATE_TO_WAREHOUSE = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
    INSERT (SALES_KEY, CUSTOMER_KEY, INVOICE_ID, DATE_DIM_KEY, TOTAL_SALE_AMT, SOURCE_ID, DATE_TO_WAREHOUSE)
    VALUES (SALES_FACT_SEQ.NEXTVAL, s.CUSTOMER_KEY, s.INVOICE_ID, s.DATE_KEY, s.TOTAL_SALE_AMT,
            s.SOURCE_ID, CURRENT_TIMESTAMP());
