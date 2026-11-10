-- Track dimension: one row per track, flattened with its album, artist, genre and media type.
select
    t.track_id,
    t.track_name,
    a.album_title,
    ar.artist_name,
    g.genre_name,
    m.media_type_name,
    m.media_type_name like '%video%' as is_video,
    t.composer,
    t.duration_ms,
    round(t.duration_ms / 60000.0, 2) as duration_minutes,
    t.list_price
from {{ ref('stg_tracks') }} t
left join {{ ref('stg_albums') }}      a  on t.album_id = a.album_id
left join {{ ref('stg_artists') }}     ar on a.artist_id = ar.artist_id
left join {{ ref('stg_genres') }}      g  on t.genre_id = g.genre_id
left join {{ ref('stg_media_types') }} m  on t.media_type_id = m.media_type_id
