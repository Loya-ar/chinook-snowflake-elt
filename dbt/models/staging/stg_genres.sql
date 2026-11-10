-- One row per genre.
select
    cast(GenreId as integer) as genre_id,
    trim(Name)               as genre_name
from {{ ref('raw_genre') }}
