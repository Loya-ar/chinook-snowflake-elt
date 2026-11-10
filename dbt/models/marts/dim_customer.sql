-- Customer dimension: one row per customer, with their first and latest purchase dates.
with customers as (
    select * from {{ ref('stg_customers') }}
),

purchase_dates as (
    select
        customer_id,
        min(invoice_date) as first_invoice_date,
        max(invoice_date) as last_invoice_date,
        count(*)          as invoice_count
    from {{ ref('stg_invoices') }}
    group by customer_id
)

select
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.company,
    c.city,
    c.state,
    c.country,
    c.email,
    c.support_rep_id,
    p.first_invoice_date,
    p.last_invoice_date,
    coalesce(p.invoice_count, 0)       as invoice_count
from customers c
left join purchase_dates p using (customer_id)
