DROP TRIGGER IF EXISTS trigger_flag ON osm_peak_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_peak_point;
DROP TRIGGER IF EXISTS trigger_refresh ON mountain_peak_point.updates;

CREATE SCHEMA IF NOT EXISTS mountain_peak_point;

CREATE TABLE IF NOT EXISTS mountain_peak_point.osm_ids
(
    osm_id bigint
);

-- etldoc:  osm_peak_point ->  osm_peak_point
CREATE OR REPLACE FUNCTION update_osm_peak_point(full_update boolean) RETURNS void AS
$$
    UPDATE osm_peak_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM mountain_peak_point.osm_ids))
      AND COALESCE(tags -> 'name:latin', tags -> 'name:nonlatin', tags -> 'name_int') IS NULL
      AND tags != update_tags(tags, geometry)
$$ LANGUAGE SQL;

SELECT update_osm_peak_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION mountain_peak_point.store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE') THEN
        INSERT INTO mountain_peak_point.osm_ids VALUES (OLD.osm_id);
    ELSE
        INSERT INTO mountain_peak_point.osm_ids VALUES (NEW.osm_id);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS mountain_peak_point.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION mountain_peak_point.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO mountain_peak_point.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mountain_peak_point.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh mountain_peak_point';
    PERFORM update_osm_peak_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM mountain_peak_point.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM mountain_peak_point.updates;

    RAISE LOG 'Refresh mountain_peak_point done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_peak_point
    FOR EACH ROW
EXECUTE PROCEDURE mountain_peak_point.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_peak_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE mountain_peak_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON mountain_peak_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE mountain_peak_point.refresh();
