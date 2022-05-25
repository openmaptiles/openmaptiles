DROP TRIGGER IF EXISTS trigger_flag ON osm_poi_point;
DROP TRIGGER IF EXISTS trigger_refresh ON poi_point.updates;

-- etldoc:  osm_poi_point ->  osm_poi_point
CREATE OR REPLACE FUNCTION update_osm_poi_point() RETURNS void AS
$$
BEGIN
    UPDATE osm_poi_point
    SET subclass = 'subway'
    WHERE station = 'subway'
      AND subclass = 'station';

    UPDATE osm_poi_point
    SET subclass = 'halt'
    WHERE funicular = 'yes'
      AND subclass = 'station';

    -- ATM without name 
    -- use either operator or network
    -- (using name for ATM is discouraged, see osm wiki)
    UPDATE osm_poi_point
    SET (name, tags) = (
        COALESCE(tags -> 'operator', tags -> 'network'),
        tags || hstore('name', COALESCE(tags -> 'operator', tags -> 'network'))
    )
    WHERE subclass = 'atm'
      AND name = ''
      AND COALESCE(tags -> 'operator', tags -> 'network') IS NOT NULL;

    UPDATE osm_poi_point
    SET tags = update_tags(tags, geometry)
    WHERE COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_poi_point();

-- etldoc:  osm_poi_stop_rank ->  osm_poi_point
CREATE OR REPLACE FUNCTION update_osm_poi_point_agg() RETURNS void AS
$$
BEGIN
    UPDATE osm_poi_point p
    SET
        agg_stop = CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                THEN 1
        END
    WHERE
        agg_stop != CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                THEN 1
        END;

    UPDATE osm_poi_point p
    SET
        agg_stop = (
        CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                     AND r.rk IS NULL OR r.rk = 1
                THEN 1
        END)
    FROM osm_poi_stop_rank r
    WHERE p.osm_id = r.osm_id AND
        agg_stop != (
        CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                     AND r.rk IS NULL OR r.rk = 1
                THEN 1
        END);

END;
$$ LANGUAGE plpgsql;

ALTER TABLE osm_poi_point
    ADD COLUMN IF NOT EXISTS agg_stop integer DEFAULT NULL;
SELECT update_osm_poi_point_agg();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS poi_point;

CREATE TABLE IF NOT EXISTS poi_point.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION poi_point.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO poi_point.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION poi_point.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh poi_point';
    PERFORM update_osm_poi_point();
    REFRESH MATERIALIZED VIEW osm_poi_stop_centroid;
    REFRESH MATERIALIZED VIEW osm_poi_stop_rank;
    PERFORM update_osm_poi_point_agg();
    -- noinspection SqlWithoutWhere
    DELETE FROM poi_point.updates;

    RAISE LOG 'Refresh poi_point done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_poi_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE poi_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON poi_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE poi_point.refresh();
