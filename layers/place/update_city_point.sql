DROP TRIGGER IF EXISTS trigger_flag ON osm_city_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_city_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_city.updates;

CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE SCHEMA IF NOT EXISTS place_city;

CREATE TABLE IF NOT EXISTS place_city.osm_ids
(
    osm_id bigint PRIMARY KEY
);

CREATE OR REPLACE FUNCTION update_osm_city_point(full_update boolean) RETURNS void AS
$$
    -- etldoc: ne_10m_populated_places -> osm_city_point
    -- etldoc: osm_city_point          -> osm_city_point

    WITH important_city_point AS (
        SELECT osm.osm_id, ne.scalerank
        FROM osm_city_point AS osm
             -- Clear OSM key:rank ( https://github.com/openmaptiles/openmaptiles/issues/108 )
             LEFT JOIN ne_10m_populated_places AS ne ON
            (
                (osm.tags ? 'wikidata' AND osm.tags->'wikidata' = ne.wikidataid) OR
                lower(osm.name) IN (lower(ne.name), lower(ne.namealt), lower(ne.meganame), lower(ne.name_en), lower(ne.nameascii)) OR
                lower(osm.name_en) IN (lower(ne.name), lower(ne.namealt), lower(ne.meganame), lower(ne.name_en), lower(ne.nameascii)) OR
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
    WHERE (full_update OR osm.osm_id IN (SELECT osm_id FROM place_city.osm_ids))
      AND rank IS DISTINCT FROM CASE WHEN scalerank <= 5 THEN scalerank + 1 ELSE scalerank END
      AND osm.osm_id = ne.osm_id;

    UPDATE osm_city_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_city.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

$$ LANGUAGE SQL;

SELECT update_osm_city_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION place_city.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_city.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS place_city.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_city.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_city.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_city.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh place_city rank';

    -- Analyze tracking and source tables before performing update
    ANALYZE place_city.osm_ids;
    ANALYZE osm_city_point;

    PERFORM update_osm_city_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM place_city.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM place_city.updates;

    RAISE LOG 'Refresh place_city done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_city_point
    FOR EACH ROW
EXECUTE PROCEDURE place_city.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_city_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE place_city.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_city.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_city.refresh();
