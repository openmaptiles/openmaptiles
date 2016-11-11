
-- etldoc: layer_water_name[shape=record fillcolor=lightpink, style="rounded,filled",  
-- etldoc:     label="layer_water_name | <z9_13> z9_13 | <z14_> z14_" ] ;

CREATE OR REPLACE FUNCTION layer_water_name(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, class text) AS $$
    -- etldoc: osm_water_lakeline ->  layer_water_name:z9_13
    -- etldoc: osm_water_lakeline ->  layer_water_name:z14_    
    SELECT osm_id, geometry, name, name_en, 'lake'::text AS class
    FROM osm_water_lakeline
    WHERE geometry && bbox
      AND name <> ''
      AND ((zoom_level BETWEEN 9 AND 13 AND LineLabel(zoom_level, NULLIF(name, ''), geometry))
        OR (zoom_level >= 14))
    ORDER BY ST_Length(geometry) DESC;
$$ LANGUAGE SQL IMMUTABLE;
