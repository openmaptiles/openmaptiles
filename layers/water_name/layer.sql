CREATE OR REPLACE FUNCTION layer_water_name(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, class text) AS $$
    SELECT osm_id, geometry, name, name_en, 'lake'::text AS class
    FROM osm_water_lakeline
    WHERE geometry && bbox
      AND name <> ''
      AND ((zoom_level BETWEEN 10 AND 13 AND LineLabel(zoom_level, NULLIF(name, ''), geometry))
        OR (zoom_level >= 14))
    ORDER BY ST_Length(geometry) DESC;
$$ LANGUAGE SQL IMMUTABLE;
