"""Fail if fct_sales_line does not have one row per invoice line in the seed.

Usage: python row_count.py path/to/chinook.duckdb
Runs with the dbt virtualenv's Python, which has duckdb installed.
"""

import sys

import duckdb

con = duckdb.connect(sys.argv[1], read_only=True)
seed_rows = con.execute("select count(*) from raw.raw_invoice_line").fetchone()[0]
fact_rows = con.execute("select count(*) from marts.fct_sales_line").fetchone()[0]
con.close()

print(f"raw.raw_invoice_line: {seed_rows} rows, marts.fct_sales_line: {fact_rows} rows")
if seed_rows == 0 or fact_rows != seed_rows:
    sys.exit(f"Row-count check failed: expected {seed_rows} fact rows, found {fact_rows}")
print("Row-count check passed")
