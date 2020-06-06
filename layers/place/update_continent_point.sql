DROP TRIGGER IF EXISTS trigger_flag ON osm_continent_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_continent_point.updates;

-- etldoc:  osm_continent_point ->  osm_continent_point
CREATE OR REPLACE FUNCTION update_osm_continent_point() RETURNS void AS
$$
BEGIN
    UPDATE osm_continent_point
    SET tags = update_tags(tags, geometry)
    WHERE COALESCE(tags -> 'name:latin', tags -> 'name:nonlatin', tags -> 'name_int') IS NULL;

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_continent_point();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS place_continent_point;

CREATE TABLE IF NOT EXISTS place_continent_point.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_continent_point.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_continent_point.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_continent_point.refresh() RETURNS trigger AS
$$
BEGIN
    RAISE LOG 'Refresh place_continent_point';
    PERFORM update_osm_continent_point();
    -- noinspection SqlWithoutWhere
    DELETE FROM place_continent_point.updates;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_continent_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE place_continent_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_continent_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_continent_point.refresh();
