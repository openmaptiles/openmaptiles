
-- etldoc: layer_place[shape=record fillcolor=lightpink, style="rounded,filled",  
-- etldoc:     label="layer_place | <zall> z0-z14_ " ] ;

-- etldoc: layer_country -> layer_place
-- etldoc: layer_state   -> layer_place
-- etldoc: layer_city    -> layer_place

CREATE OR REPLACE FUNCTION layer_place(bbox geometry, zoom_level int, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, class text, "rank" int) AS $$
    SELECT osm_id, geometry, name, name_en, 'country' AS class, "rank" FROM layer_country(bbox, zoom_level)
    UNION ALL
    SELECT osm_id, geometry, name, name_en, 'state' AS class, "rank" FROM layer_state(bbox, zoom_level)
    UNION ALL
    SELECT osm_id, geometry, name, name_en, class::text, "rank" FROM layer_city(bbox, zoom_level, pixel_width)
$$ LANGUAGE SQL IMMUTABLE;
