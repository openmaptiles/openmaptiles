DROP TRIGGER IF EXISTS trigger_flag ON osm_city_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_city.updates;

CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE OR REPLACE FUNCTION update_osm_city_point() RETURNS VOID AS $$
BEGIN

  -- Clear  OSM key:rank ( https://github.com/openmaptiles/openmaptiles/issues/108 )
  -- etldoc: osm_city_point          -> osm_city_point
  UPDATE osm_city_point AS osm  SET "rank" = NULL WHERE "rank" IS NOT NULL;

  -- etldoc: ne_10m_populated_places -> osm_city_point
  -- etldoc: osm_city_point          -> osm_city_point

  WITH important_city_point AS (
      SELECT osm.geometry, osm.osm_id, osm.name, osm.name_en, ne.scalerank, ne.labelrank
      FROM ne_10m_populated_places AS ne, osm_city_point AS osm
      WHERE
      (
          ne.name ILIKE osm.name OR
          ne.name ILIKE osm.name_en OR
          ne.namealt ILIKE osm.name OR
          ne.namealt ILIKE osm.name_en OR
          ne.meganame ILIKE osm.name OR
          ne.meganame ILIKE osm.name_en OR
          ne.gn_ascii ILIKE osm.name OR
          ne.gn_ascii ILIKE osm.name_en OR
          ne.nameascii ILIKE osm.name OR
          ne.nameascii ILIKE osm.name_en OR
          ne.name = unaccent(osm.name)
      )
      AND osm.place IN ('city', 'town', 'village')
      AND ST_DWithin(ne.geometry, osm.geometry, 50000)
  )
  UPDATE osm_city_point AS osm
  -- Move scalerank to range 1 to 10 and merge scalerank 5 with 6 since not enough cities
  -- are in the scalerank 5 bucket
  SET "rank" = CASE WHEN scalerank <= 5 THEN scalerank + 1 ELSE scalerank END
  FROM important_city_point AS ne
  WHERE osm.osm_id = ne.osm_id;

  UPDATE osm_city_point
  SET tags = delete_empty_keys(tags) || get_basic_names(tags, geometry)
  WHERE COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL;

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_city_point();

CREATE INDEX IF NOT EXISTS osm_city_point_rank_idx ON osm_city_point("rank");

-- Handle updates

CREATE SCHEMA IF NOT EXISTS place_city;

CREATE TABLE IF NOT EXISTS place_city.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION place_city.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO place_city.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION place_city.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh place_city rank';
    PERFORM update_osm_city_point();
    DELETE FROM place_city.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_city_point
    FOR EACH STATEMENT
    EXECUTE PROCEDURE place_city.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON place_city.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE place_city.refresh();
