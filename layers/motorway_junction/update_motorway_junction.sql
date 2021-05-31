DROP TRIGGER IF EXISTS trigger_flag ON osm_motorway_junction;
DROP TRIGGER IF EXISTS trigger_store ON osm_motorway_junction;
DROP TRIGGER IF EXISTS trigger_refresh ON highway_motorway_junction.updates;

CREATE SCHEMA IF NOT EXISTS highway_motorway_junction;

CREATE TABLE IF NOT EXISTS highway_motorway_junction.osm_ids
(
    osm_id bigint
);

-- etldoc:  osm_motorway_junction ->  osm_motorway_junction
CREATE OR REPLACE FUNCTION update_osm_motorway_junction(full_update boolean) RETURNS void AS
$$
    UPDATE osm_motorway_junction
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM highway_motorway_junction.osm_ids))
      AND COALESCE(tags -> 'name:latin', tags -> 'name:nonlatin', tags -> 'name_int') IS NULL
      AND tags != update_tags(tags, geometry)
$$ LANGUAGE SQL;

SELECT update_osm_motorway_junction(true);

-- Handle updates

CREATE OR REPLACE FUNCTION highway_motorway_junction.store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE') THEN
        INSERT INTO highway_motorway_junction.osm_ids VALUES (OLD.osm_id);
    ELSE
        INSERT INTO highway_motorway_junction.osm_ids VALUES (NEW.osm_id);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS highway_motorway_junction.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION highway_motorway_junction.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO highway_motorway_junction.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION highway_motorway_junction.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh highway_motorway_junction';
    PERFORM update_osm_motorway_junction(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM highway_motorway_junction.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM highway_motorway_junction.updates;

    RAISE LOG 'Refresh highway_motorway_junction done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_motorway_junction
    FOR EACH ROW
EXECUTE PROCEDURE highway_motorway_junction.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_motorway_junction
    FOR EACH STATEMENT
EXECUTE PROCEDURE highway_motorway_junction.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON highway_motorway_junction.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE highway_motorway_junction.refresh();
