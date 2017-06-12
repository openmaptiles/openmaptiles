DROP TRIGGER IF EXISTS trigger_flag_point ON osm_water_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON water_point.updates;

-- etldoc:  osm_water_polygon ->  osm_water_point
-- etldoc:  lake_centerline ->  osm_water_point
DROP MATERIALIZED VIEW IF EXISTS  osm_water_point CASCADE;

CREATE MATERIALIZED VIEW osm_water_point AS (
    SELECT
        wp.osm_id, ST_PointOnSurface(wp.geometry) AS geometry,
        wp.name, wp.name_en, wp.name_de, wp.tags, ST_Area(wp.geometry) AS area
    FROM osm_water_polygon AS wp
    LEFT JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
    WHERE ll.osm_id IS NULL AND wp.name <> ''
);
CREATE INDEX IF NOT EXISTS osm_water_point_geometry_idx ON osm_water_point USING gist (geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS water_point;

CREATE TABLE IF NOT EXISTS water_point.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION water_point.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO water_point.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION water_point.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh water_point';
    REFRESH MATERIALIZED VIEW osm_water_point;
    DELETE FROM water_point.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag_point
    AFTER INSERT OR UPDATE OR DELETE ON osm_water_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE water_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON water_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE water_point.refresh();
