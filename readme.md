# Chinook OLTP → Snowflake DW (ADF + Data Flows)

This repo contains the assets to replicate the class workshop:
- Extract Chinook tables from **Azure SQL** → **Azure Blob/Parquet** (ADF Copy)
- Land Parquet to **Snowflake STAGE** tables
- Build **DW dimensions** and **SALES_FACT**
- Validate row counts end-to-end

## Tech
- Azure Data Factory (ADF)
- Azure SQL DB
- Azure Storage (Blob)
- Snowflake (Warehouse, DB: `CHINOOK_DB`)

## Prereqs
- Snowflake warehouse running (`COMPUTE_WH` or your WH)
- Database: `CHINOOK_DB`
- ADF linked services: Storage, SQL DB, Key Vault, Snowflake
- ADF MI has Storage Blob Contributor on your container

## Run Order (Snowflake)
1. `sql/01_create_stage_schema.sql` *(optional if tables created via ADF)*
2. `sql/02_create_dw_schema.sql`
3. `sql/03_load_date_dim.sql`
4. `sql/04_load_time_dim.sql`
5. Land data to `STAGE.*` using ADF pipelines
6. `sql/05_merge_artist_dim.sql`
7. **Either** run `sql/06_merge_customer_dim.sql` **or** run ADF Data Flow `DF_Load_Customer_DIM`
8. `sql/07_load_sales_fact.sql`
9. `sql/08_validation_counts.sql`

## ADF Pipelines / Data Flows
- **Pipeline:** `extract_SQLDB_PL`
  - Parameter: `table_names_array = ["Customer","Artist","Album","Invoice"]`
  - Activities: `ForEach` → Copy SQL table → Parquet (Blob) → Copy to Snowflake STAGE (or via staging Linked Service)
- **Pipeline:** `Parquest_2_snowstage_pl` *(if you split landing to STAGE)*
- **Data Flow:** `DF_Load_Customer_DIM`
  - Sources: `STAGE.CUSTOMER` (+ optional lookup)
  - Transform: derive `CUSTOMER_HASH` = `sha2( concat(cols), 256 )`
  - Sink: `DW.CUSTOMER_DIM` (UPSERT using `CUSTOMER_ID`)

## Validation
See `sql/08_validation_counts.sql` for:
- Stage counts (CUSTOMER/ARTIST/ALBUM/INVOICE)
- DW counts (DATE_DIM/TIME_DIM/CUSTOMER_DIM/ARTIST_DIM)
- FACT count + sample

