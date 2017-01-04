
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

CREATE SCHEMA water_lakeline;

CREATE TABLE IF NOT EXISTS water_lakeline.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION water_lakeline.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO water_lakeline.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;    
$$ language plpgsql;

CREATE OR REPLACE FUNCTION water_lakeline.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh water_lakeline';
    REFRESH MATERIALIZED VIEW osm_water_lakeline;
    DELETE FROM water_lakeline.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER water_lakeline.trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_water_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE water_lakeline.flag();

CREATE CONSTRAINT TRIGGER water_lakeline.trigger_refresh
    AFTER INSERT ON water_lakeline.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE water_lakeline.refresh();
