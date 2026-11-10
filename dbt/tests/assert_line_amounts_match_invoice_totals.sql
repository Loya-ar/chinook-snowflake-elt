-- Fails if any invoice's line items do not add up to the invoice total.
-- Returns the mismatched invoices; an empty result means the test passes.
with line_totals as (
    select invoice_id, sum(line_amount) as lines_total
    from {{ ref('fct_sales_line') }}
    group by invoice_id
)

select
    i.invoice_id,
    i.invoice_total,
    l.lines_total
from {{ ref('stg_invoices') }} i
left join line_totals l on i.invoice_id = l.invoice_id
where l.lines_total is null
   or l.lines_total <> i.invoice_total
