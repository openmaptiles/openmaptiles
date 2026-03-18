DROP TRIGGER IF EXISTS trigger_flag ON osm_island_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_island_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_island_point.updates;

CREATE SCHEMA IF NOT EXISTS place_island_point;

CREATE TABLE IF NOT EXISTS place_island_point.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc:  osm_island_point ->  osm_island_point
CREATE OR REPLACE FUNCTION update_osm_island_point(full_update boolean) RETURNS void AS
$$
    UPDATE osm_island_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_island_point.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);
$$ LANGUAGE SQL;

SELECT update_osm_island_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION place_island_point.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_island_point.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS place_island_point.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_island_point.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_island_point.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_island_point.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh place_island_point';

    -- Analyze tracking and source tables before performing update
    ANALYZE place_island_point.osm_ids;
    ANALYZE osm_island_point;

    PERFORM update_osm_island_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM place_island_point.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM place_island_point.updates;

    RAISE LOG 'Refresh place_island_point done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_island_point
    FOR EACH ROW
    WHEN (pg_trigger_depth() < 1)
EXECUTE PROCEDURE place_island_point.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_island_point
    FOR EACH STATEMENT
    WHEN (pg_trigger_depth() < 1)
EXECUTE PROCEDURE place_island_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_island_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_island_point.refresh();
