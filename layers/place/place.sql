CREATE OR REPLACE FUNCTION layer_place(bbox geometry, zoom_level int, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, place text, abbrev text, postal text, scalerank int) AS $$
    SELECT osm_id, geometry, name, name AS name_en, 'country' AS place, abbrev, postal, scalerank FROM layer_country(bbox, zoom_level)
    UNION ALL
    SELECT osm_id, geometry, name, name_en, 'state' AS place, abbrev, postal, scalerank FROM layer_state(bbox, zoom_level)
    UNION ALL
    SELECT osm_id, geometry, name, name_en, place, NULL AS abbrev, NULL AS postal, scalerank FROM layer_city(bbox, zoom_level, pixel_width)
$$ LANGUAGE SQL IMMUTABLE;
