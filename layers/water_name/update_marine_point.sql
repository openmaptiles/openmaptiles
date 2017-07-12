DROP TRIGGER IF EXISTS trigger_flag ON osm_marine_point;
DROP TRIGGER IF EXISTS trigger_refresh ON water_name_marine.updates;

CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE OR REPLACE FUNCTION update_osm_marine_point() RETURNS VOID AS $$
BEGIN
  -- etldoc: osm_marine_point          -> osm_marine_point
  UPDATE osm_marine_point AS osm SET "rank" = NULL WHERE "rank" IS NOT NULL;

  -- etldoc: ne_10m_geography_marine_polys -> osm_marine_point
  -- etldoc: osm_marine_point              -> osm_marine_point

  WITH important_marine_point AS (
      SELECT osm.geometry, osm.osm_id, osm.name, osm.name_en, ne.scalerank
      FROM ne_10m_geography_marine_polys AS ne, osm_marine_point AS osm
      WHERE ne.name ILIKE osm.name
  )
  UPDATE osm_marine_point AS osm
  SET "rank" = scalerank
  FROM important_marine_point AS ne
  WHERE osm.osm_id = ne.osm_id;

  UPDATE osm_marine_point
  SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry)
  WHERE COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL;

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_marine_point();

CREATE INDEX IF NOT EXISTS osm_marine_point_rank_idx ON osm_marine_point("rank");

-- Handle updates
CREATE SCHEMA IF NOT EXISTS water_name_marine;

CREATE TABLE IF NOT EXISTS water_name_marine.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION water_name_marine.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO water_name_marine.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION water_name_marine.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh water_name_marine rank';
    PERFORM update_osm_marine_point();
    DELETE FROM water_name_marine.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_marine_point
    FOR EACH STATEMENT
    EXECUTE PROCEDURE water_name_marine.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON water_name_marine.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE water_name_marine.refresh();
