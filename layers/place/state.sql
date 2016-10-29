CREATE OR REPLACE FUNCTION layer_state(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, "rank" int) AS $$
    SELECT osm_id, geometry, name, name_en, "rank"
    FROM osm_state_point
    WHERE geometry && bbox AND (
        (zoom_level = 3 AND "rank" <= 1) OR
        (zoom_level >= 4)
    )
    ORDER BY "rank" ASC;
$$ LANGUAGE SQL IMMUTABLE;
