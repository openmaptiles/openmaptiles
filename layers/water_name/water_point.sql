
-- etldoc:  osm_water_polygon ->  osm_water_point
-- etldoc:  lake_centerline ->  osm_water_point
CREATE MATERIALIZED VIEW osm_water_point AS (
    SELECT
        wp.osm_id, topoint(wp.geometry) AS geometry,
        wp.name, wp.name_en, ST_Area(wp.geometry) AS area
    FROM osm_water_polygon AS wp
    LEFT JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
    WHERE ll.osm_id IS NULL AND wp.name <> ''
) WITH NO DATA;
CREATE INDEX IF NOT EXISTS osm_water_point_geometry_idx ON osm_water_point USING gist (geometry);

-- Handle updates

CREATE SCHEMA water_name;

CREATE TABLE IF NOT EXISTS water_name.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION water_name.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO water_name.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;    
$$ language plpgsql;

CREATE OR REPLACE FUNCTION water_name.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh water_name';
    REFRESH MATERIALIZED VIEW osm_water_point;
    DELETE FROM water_name.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_water_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE water_name.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON water_name.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE water_name.refresh();
