DROP TABLE IF EXISTS osm_water_point;

-- etldoc:  osm_water_polygon ->  osm_water_point
-- etldoc:  lake_centerline ->  osm_water_point
CREATE TABLE IF NOT EXISTS osm_water_point AS (
    SELECT
        wp.osm_id, topoint(wp.geometry) AS geometry,
        wp.name, wp.name_en, ST_Area(wp.geometry) AS area
    FROM osm_water_polygon AS wp
    LEFT JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
    WHERE ll.osm_id IS NULL AND wp.name <> ''
);

CREATE INDEX IF NOT EXISTS osm_water_point_geometry_idx ON osm_water_point USING gist (geometry);
