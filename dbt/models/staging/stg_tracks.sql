-- One row per track, with its album, genre, media type, length and list price.
select
    cast(TrackId as integer)          as track_id,
    trim(Name)                        as track_name,
    cast(AlbumId as integer)          as album_id,
    cast(MediaTypeId as integer)      as media_type_id,
    cast(GenreId as integer)          as genre_id,
    nullif(trim(Composer), '')        as composer,
    cast(Milliseconds as integer)     as duration_ms,
    cast(UnitPrice as decimal(10, 2)) as list_price
from {{ ref('raw_track') }}
