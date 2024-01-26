DROP TRIGGER IF EXISTS trigger_flag ON osm_marine_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_marine_point;
DROP TRIGGER IF EXISTS trigger_refresh ON water_name_marine.updates;

CREATE SCHEMA IF NOT EXISTS water_name_marine;

CREATE TABLE IF NOT EXISTS water_name_marine.osm_ids
(
    osm_id bigint PRIMARY KEY
);

CREATE OR REPLACE FUNCTION update_osm_marine_point(full_update boolean) RETURNS void AS
$$
    -- etldoc: ne_10m_geography_marine_polys -> osm_marine_point
    -- etldoc: osm_marine_point              -> osm_marine_point

    WITH important_marine_point AS (
        SELECT osm.osm_id, ne.scalerank
        FROM osm_marine_point AS osm
             LEFT JOIN ne_10m_geography_marine_polys AS ne ON
            (
                lower(trim(regexp_replace(ne.name, '\\s+', ' ', 'g'))) IN (lower(osm.name), lower(osm.tags->'name:en'), lower(osm.tags->'name:es'))
                    OR substring(lower(trim(regexp_replace(ne.name, '\\s+', ' ', 'g'))) FROM 1 FOR length(lower(osm.name))) = lower(osm.name)
            )
            AND ST_DWithin(ne.geometry, osm.geometry, 50000)
    )
    UPDATE osm_marine_point AS osm
    SET "rank" = scalerank
    FROM important_marine_point AS ne
    WHERE (full_update OR osm.osm_id IN (SELECT osm_id FROM water_name_marine.osm_ids))
      AND osm.osm_id = ne.osm_id
      AND "rank" IS DISTINCT FROM scalerank;

    UPDATE osm_marine_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM water_name_marine.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

$$ LANGUAGE SQL;

SELECT update_osm_marine_point(true);

CREATE INDEX IF NOT EXISTS osm_marine_point_rank_idx ON osm_marine_point ("rank");

-- Handle updates

CREATE OR REPLACE FUNCTION water_name_marine.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO water_name_marine.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS water_name_marine.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION water_name_marine.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO water_name_marine.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION water_name_marine.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh water_name_marine rank';

    -- Analyze tracking and source tables before performing update
    ANALYZE water_name_marine.osm_ids;
    ANALYZE osm_marine_point;

    PERFORM update_osm_marine_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM water_name_marine.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM water_name_marine.updates;

    RAISE LOG 'Refresh water_name_marine done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_marine_point
    FOR EACH ROW
EXECUTE PROCEDURE water_name_marine.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_marine_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE water_name_marine.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON water_name_marine.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE water_name_marine.refresh();
