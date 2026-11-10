-- One row per album.
select
    cast(AlbumId as integer)  as album_id,
    trim(Title)               as album_title,
    cast(ArtistId as integer) as artist_id
from {{ ref('raw_album') }}
