DROP TRIGGER IF EXISTS trigger_flag ON osm_country_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_country.updates;

ALTER TABLE osm_country_point DROP CONSTRAINT IF EXISTS osm_country_point_rank_constraint;

-- etldoc: ne_10m_admin_0_countries   -> osm_country_point
-- etldoc: osm_country_point          -> osm_country_point

CREATE OR REPLACE FUNCTION update_osm_country_point() RETURNS VOID AS $$
BEGIN

  WITH important_country_point AS (
      SELECT osm.geometry, osm.osm_id, osm.name, COALESCE(NULLIF(osm.name_en, ''), ne.name) AS name_en, ne.scalerank, ne.labelrank
      FROM ne_10m_admin_0_countries AS ne, osm_country_point AS osm
      WHERE
      -- We only match whether the point is within the Natural Earth polygon
      -- because name matching is to difficult since OSM does not contain good
      -- enough coverage of ISO codesy
      ST_Within(osm.geometry, ne.geometry)
      -- We leave out tiny countries
      AND ne.scalerank <= 1
  )
  UPDATE osm_country_point AS osm
  -- Normalize both scalerank and labelrank into a ranking system from 1 to 6
  -- where the ranks are still distributed uniform enough across all countries
  SET "rank" = LEAST(6, CEILING((scalerank + labelrank)/2.0))
  FROM important_country_point AS ne
  WHERE osm.osm_id = ne.osm_id;

  UPDATE osm_country_point AS osm
  SET "rank" = 6
  WHERE "rank" IS NULL;

  -- TODO: This shouldn't be necessary? The rank function makes something wrong...
  UPDATE osm_country_point AS osm
  SET "rank" = 1
  WHERE "rank" = 0;

  UPDATE osm_country_point
  SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry)
  WHERE COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL;

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_country_point();

-- ALTER TABLE osm_country_point ADD CONSTRAINT osm_country_point_rank_constraint CHECK("rank" BETWEEN 1 AND 6);
CREATE INDEX IF NOT EXISTS osm_country_point_rank_idx ON osm_country_point("rank");

-- Handle updates

CREATE SCHEMA IF NOT EXISTS place_country;

CREATE TABLE IF NOT EXISTS place_country.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION place_country.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO place_country.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION place_country.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh place_country rank';
    PERFORM update_osm_country_point();
    DELETE FROM place_country.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_country_point
    FOR EACH STATEMENT
    EXECUTE PROCEDURE place_country.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON place_country.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE place_country.refresh();
