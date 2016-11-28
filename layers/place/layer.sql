
-- etldoc: layer_place[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_place | <zall> z0-z14_ " ] ;

-- etldoc: layer_continent -> layer_place
-- etldoc: layer_country   -> layer_place
-- etldoc: layer_state     -> layer_place
-- etldoc: layer_city      -> layer_place

CREATE OR REPLACE FUNCTION layer_place(bbox geometry, zoom_level int, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, class text, subclass text, "rank" int, capital INT) AS $$
    SELECT
        osm_id, geometry, name, name_en,
        'continent' AS class, 'continent' AS subclass, 1 AS "rank", NULL::int AS capital
    FROM osm_continent_point
    WHERE geometry && bbox AND zoom_level < 4
    UNION ALL
    SELECT
        osm_id, geometry, name, name_en,
        'country' AS class, 'country' AS subclass,"rank", NULL::int AS capital
    FROM layer_country(bbox, zoom_level)
    UNION ALL
    SELECT
        osm_id, geometry, name, name_en,
        'state' AS class, 'state' AS subclass, "rank", NULL::int AS capital
    FROM layer_state(bbox, zoom_level)
    UNION ALL
    SELECT
        osm_id, geometry, name, name_en,
        place_class(place::text) AS class, place::text AS subclass, "rank", capital
    FROM layer_city(bbox, zoom_level, pixel_width)
$$ LANGUAGE SQL IMMUTABLE;
