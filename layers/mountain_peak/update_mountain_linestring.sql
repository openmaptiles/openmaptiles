DROP TRIGGER IF EXISTS trigger_flag ON osm_mountain_linestring;
DROP TRIGGER IF EXISTS trigger_store ON osm_mountain_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON mountain_linestring.updates;

CREATE SCHEMA IF NOT EXISTS mountain_linestring;

CREATE TABLE IF NOT EXISTS mountain_linestring.osm_ids
(
    osm_id bigint
);

-- etldoc:  osm_mountain_linestring ->  osm_mountain_linestring
CREATE OR REPLACE FUNCTION update_osm_mountain_linestring(full_update boolean) RETURNS void AS
$$
    UPDATE osm_mountain_linestring
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM mountain_linestring.osm_ids))
      AND COALESCE(tags -> 'name:latin', tags -> 'name:nonlatin', tags -> 'name_int') IS NULL
      AND tags != update_tags(tags, geometry)
$$ LANGUAGE SQL;

SELECT update_osm_mountain_linestring(true);

-- Handle updates

CREATE OR REPLACE FUNCTION mountain_linestring.store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE') THEN
        INSERT INTO mountain_linestring.osm_ids VALUES (OLD.osm_id);
    ELSE
        INSERT INTO mountain_linestring.osm_ids VALUES (NEW.osm_id);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS mountain_linestring.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION mountain_linestring.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO mountain_linestring.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mountain_linestring.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh mountain_linestring';
    PERFORM update_osm_mountain_linestring(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM mountain_linestring.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM mountain_linestring.updates;

    RAISE LOG 'Refresh mountain_linestring done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_mountain_linestring
    FOR EACH ROW
EXECUTE PROCEDURE mountain_linestring.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_mountain_linestring
    FOR EACH STATEMENT
EXECUTE PROCEDURE mountain_linestring.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON mountain_linestring.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE mountain_linestring.refresh();
