CREATE OR REPLACE FUNCTION layer_country(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, "rank" int) AS $$
    SELECT osm_id, geometry, name, name_en, "rank" FROM osm_country_point
    WHERE geometry && bbox AND "rank" <= (zoom_level + 2)
    ORDER BY "rank" ASC, length(name) ASC;
$$ LANGUAGE SQL IMMUTABLE;
