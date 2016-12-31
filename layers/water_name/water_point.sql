
-- etldoc:  osm_water_polygon ->  osm_water_point
-- etldoc:  lake_centerline ->  osm_water_point

CREATE OR REPLACE FUNCTION osm_water_point(bbox geometry, zoom_level int)
    RETURNS TABLE(geometry geometry, osm_id bigint, name varchar, name_en varchar, area float) AS $$
    SELECT
        topoint(wp.geometry) AS geometry, wp.osm_id, 
        wp.name, wp.name_en, ST_Area(wp.geometry) AS area
    FROM osm_water_polygon AS wp
    LEFT JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
    WHERE ll.osm_id IS NULL AND wp.name <> '' AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

