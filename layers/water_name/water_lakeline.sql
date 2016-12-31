
-- etldoc:  osm_water_polygon ->  osm_water_lakeline
-- etldoc:  lake_centerline  ->  osm_water_lakeline
CREATE OR REPLACE FUNCTION osm_water_lakeline(bbox geometry, zoom_level int)
    RETURNS TABLE(geometry geometry, osm_id bigint, name varchar, name_en varchar, area float) AS $$
	SELECT 	ll.wkb_geometry AS geometry, wp.osm_id,
		name, name_en, ST_Area(wp.geometry) AS area
    FROM osm_water_polygon AS wp
    INNER JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
    WHERE wp.name <> '' AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
