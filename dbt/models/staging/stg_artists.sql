-- One row per artist.
select
    cast(ArtistId as integer) as artist_id,
    trim(Name)                as artist_name
from {{ ref('raw_artist') }}
