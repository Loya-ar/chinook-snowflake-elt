-- One row per media type (for example MPEG audio or protected AAC).
select
    cast(MediaTypeId as integer) as media_type_id,
    trim(Name)                   as media_type_name
from {{ ref('raw_media_type') }}
