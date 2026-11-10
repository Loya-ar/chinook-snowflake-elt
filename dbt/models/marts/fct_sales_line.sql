-- Sales fact: one row per invoice line (one track sold on one invoice).
-- Join to dim_customer, dim_track and dim_date for reporting.
select
    l.invoice_line_id,
    l.invoice_id,
    i.customer_id,
    l.track_id,
    i.invoice_date,
    i.billing_country,
    l.unit_price,
    l.quantity,
    cast(l.unit_price * l.quantity as decimal(10, 2)) as line_amount
from {{ ref('stg_invoice_lines') }} l
inner join {{ ref('stg_invoices') }} i on l.invoice_id = i.invoice_id
