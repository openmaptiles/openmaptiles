
CREATE OR REPLACE FUNCTION layer_power(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, class text, name text) AS $$
    SELECT geometry, class, name
    FROM osm_power_point
    WHERE zoom_level >= 10 AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
