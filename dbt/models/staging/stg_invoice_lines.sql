-- One row per line item: which track was bought on which invoice, at what price.
select
    cast(InvoiceLineId as integer)    as invoice_line_id,
    cast(InvoiceId as integer)        as invoice_id,
    cast(TrackId as integer)          as track_id,
    cast(UnitPrice as decimal(10, 2)) as unit_price,
    cast(Quantity as integer)         as quantity
from {{ ref('raw_invoice_line') }}
