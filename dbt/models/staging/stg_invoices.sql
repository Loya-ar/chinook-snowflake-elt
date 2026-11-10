-- One row per invoice (an order), with its billing location and total.
select
    cast(InvoiceId as integer)          as invoice_id,
    cast(CustomerId as integer)         as customer_id,
    cast(InvoiceDate as date)           as invoice_date,
    trim(BillingCity)                   as billing_city,
    nullif(trim(BillingState), '')      as billing_state,
    trim(BillingCountry)                as billing_country,
    nullif(trim(BillingPostalCode), '') as billing_postal_code,
    cast(Total as decimal(10, 2))       as invoice_total
from {{ ref('raw_invoice') }}
