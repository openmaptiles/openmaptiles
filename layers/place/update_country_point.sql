DROP TRIGGER IF EXISTS trigger_flag ON osm_country_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_country.updates;

ALTER TABLE osm_country_point DROP CONSTRAINT IF EXISTS osm_country_point_rank_constraint;

-- etldoc: ne_10m_admin_0_countries   -> osm_country_point
-- etldoc: osm_country_point          -> osm_country_point

CREATE OR REPLACE FUNCTION update_osm_country_point() RETURNS VOID AS $$
BEGIN

  UPDATE osm_country_point AS osm
  SET
    "rank" = 7,
    iso3166_1_alpha_2 = COALESCE(
      NULLIF(osm.country_code_iso3166_1_alpha_2, ''),
      NULLIF(osm.iso3166_1_alpha_2, ''),
      NULLIF(osm.iso3166_1, '')
    )
  ;

  WITH important_country_point AS (
      SELECT osm.geometry, osm.osm_id, osm.name, COALESCE(NULLIF(osm.name_en, ''), ne.name) AS name_en, ne.scalerank, ne.labelrank
      FROM ne_10m_admin_0_countries AS ne, osm_country_point AS osm
      WHERE
        -- We match only countries with ISO codes to eliminate disputed countries
        iso3166_1_alpha_2 IS NOT NULL
        -- that lies inside polygon of sovereign country
        AND ST_Within(osm.geometry, ne.geometry)
  )
  UPDATE osm_country_point AS osm
  -- Normalize both scalerank and labelrank into a ranking system from 1 to 6
  -- where the ranks are still distributed uniform enough across all countries
  SET "rank" = LEAST(6, CEILING((scalerank + labelrank)/2.0))
  FROM important_country_point AS ne
  WHERE osm.osm_id = ne.osm_id;

  -- Repeat the step for archipelago countries like Philippines or Indonesia
  -- whose label point is not within country's polygon
  WITH important_country_point AS (
    SELECT
      osm.osm_id,
--       osm.name,
      ne.scalerank,
      ne.labelrank,
--       ST_Distance(osm.geometry, ne.geometry) AS distance,
      ROW_NUMBER()
      OVER (
        PARTITION BY osm.osm_id
        ORDER BY
          ST_Distance(osm.geometry, ne.geometry)
      ) AS rk
    FROM osm_country_point osm,
      ne_10m_admin_0_countries AS ne
    WHERE
      iso3166_1_alpha_2 IS NOT NULL
      AND NOT (osm."rank" BETWEEN 1 AND 6)
  )
  UPDATE osm_country_point AS osm
  -- Normalize both scalerank and labelrank into a ranking system from 1 to 6
  -- where the ranks are still distributed uniform enough across all countries
  SET "rank" = LEAST(6, CEILING((ne.scalerank + ne.labelrank)/2.0))
  FROM important_country_point AS ne
  WHERE osm.osm_id = ne.osm_id AND ne.rk = 1;

  UPDATE osm_country_point AS osm
  SET "rank" = 6
  WHERE "rank" = 7;

  -- TODO: This shouldn't be necessary? The rank function makes something wrong...
  UPDATE osm_country_point AS osm
  SET "rank" = 1
  WHERE "rank" = 0;

  UPDATE osm_country_point
  SET tags = update_tags(tags, geometry)
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
