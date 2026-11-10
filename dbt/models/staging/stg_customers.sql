-- One row per customer, with snake_case names and trimmed text.
select
    cast(CustomerId as integer)   as customer_id,
    trim(FirstName)               as first_name,
    trim(LastName)                as last_name,
    nullif(trim(Company), '')     as company,
    trim(Address)                 as address,
    trim(City)                    as city,
    nullif(trim(State), '')       as state,
    trim(Country)                 as country,
    nullif(trim(PostalCode), '')  as postal_code,
    lower(trim(Email))            as email,
    cast(SupportRepId as integer) as support_rep_id
from {{ ref('raw_customer') }}
