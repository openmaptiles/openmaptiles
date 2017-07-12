DROP TRIGGER IF EXISTS trigger_flag_line ON osm_water_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON water_lakeline.updates;

-- etldoc:  osm_water_polygon ->  osm_water_lakeline
-- etldoc:  lake_centerline  ->  osm_water_lakeline
DROP MATERIALIZED VIEW IF EXISTS osm_water_lakeline CASCADE;

CREATE MATERIALIZED VIEW osm_water_lakeline AS (
	SELECT wp.osm_id,
		ll.wkb_geometry AS geometry,
		name, name_en, name_de,
		slice_language_tags(tags) || get_basic_names(tags, ll.wkb_geometry) AS tags,
		ST_Area(wp.geometry) AS area
    FROM osm_water_polygon AS wp
    INNER JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
    WHERE wp.name <> ''
);
CREATE INDEX IF NOT EXISTS osm_water_lakeline_geometry_idx ON osm_water_lakeline USING gist(geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS water_lakeline;

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

CREATE TRIGGER trigger_flag_line
    AFTER INSERT OR UPDATE OR DELETE ON osm_water_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE water_lakeline.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON water_lakeline.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE water_lakeline.refresh();
