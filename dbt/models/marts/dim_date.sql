-- Date dimension: one row per calendar day, covering every year that has an invoice.
with bounds as (
    select
        make_date(year(min(invoice_date)), 1, 1)  as start_date,
        make_date(year(max(invoice_date)), 12, 31) as end_date
    from {{ ref('stg_invoices') }}
),

days as (
    select cast(unnest(generate_series(start_date, end_date, interval 1 day)) as date) as date_day
    from bounds
)

select
    date_day,
    year(date_day)                    as year,
    quarter(date_day)                 as quarter,
    month(date_day)                   as month,
    strftime(date_day, '%B')          as month_name,
    strftime(date_day, '%Y-%m')       as year_month,
    isodow(date_day)                  as day_of_week,  -- 1 = Monday, 7 = Sunday
    strftime(date_day, '%A')          as day_name,
    isodow(date_day) in (6, 7)        as is_weekend
from days
