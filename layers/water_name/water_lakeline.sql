
DROP TABLE IF EXISTS osm_water_lakeline CASCADE;

-- etldoc:  osm_water_polygon ->  osm_water_lakeline
-- etldoc:  lake_centerline  ->  osm_water_lakeline
CREATE TABLE IF NOT EXISTS osm_water_lakeline AS (
	SELECT wp.osm_id,
		ll.wkb_geometry AS geometry,
		name, name_en, ST_Area(wp.geometry) AS area
    FROM osm_water_polygon AS wp
    INNER JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
    WHERE wp.name <> ''
);

CREATE INDEX IF NOT EXISTS osm_water_lakeline_geometry_idx ON osm_water_lakeline USING gist(geometry);
