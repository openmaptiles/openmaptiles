
-- etldoc:  osm_water_polygon ->  osm_water_lakeline
-- etldoc:  lake_centerline  ->  osm_water_lakeline
CREATE MATERIALIZED VIEW osm_water_lakeline AS (
	SELECT wp.osm_id,
		ll.wkb_geometry AS geometry,
		name, name_en, ST_Area(wp.geometry) AS area
    FROM osm_water_polygon AS wp
    INNER JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
    WHERE wp.name <> ''
) WITH NO DATA;
CREATE INDEX IF NOT EXISTS osm_water_lakeline_geometry_idx ON osm_water_lakeline USING gist(geometry);

-- Handle updates

CREATE TABLE IF NOT EXISTS updates_osm_water_polygon(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION flag_update_osm_water_polygon() RETURNS trigger AS $$
BEGIN
    INSERT INTO updates_osm_water_polygon(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;    
$$ language plpgsql;

CREATE OR REPLACE FUNCTION refresh_osm_water_lakeline() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh osm_water_lakeline based tables';
    REFRESH MATERIALIZED VIEW osm_water_lakeline;
    DELETE FROM updates_osm_water_polygon;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_refresh_osm_water_lakeline
    AFTER INSERT OR UPDATE OR DELETE ON osm_water_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE flag_update_osm_water_polygon();

CREATE CONSTRAINT TRIGGER commit_osm_water_polygon 
    AFTER INSERT ON updates_osm_water_polygon
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE refresh_osm_water_lakeline();
