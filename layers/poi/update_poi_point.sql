DROP TRIGGER IF EXISTS trigger_flag ON osm_poi_point;
DROP TRIGGER IF EXISTS trigger_refresh ON poi_point.updates;
DROP TRIGGER IF EXISTS trigger_store ON osm_poi_point;

CREATE SCHEMA IF NOT EXISTS poi_point;

CREATE TABLE IF NOT EXISTS poi_point.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc:  osm_poi_point ->  osm_poi_point
CREATE OR REPLACE FUNCTION update_osm_poi_point(full_update bool) RETURNS void AS
$$
BEGIN
    UPDATE osm_poi_point
    SET subclass = 'subway'
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_point.osm_ids))
      AND station = 'subway'
      AND subclass = 'station';

    UPDATE osm_poi_point
    SET subclass = 'halt'
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_point.osm_ids))
      AND funicular = 'yes'
      AND subclass = 'station';

    -- ATM without name 
    -- use either operator or network
    -- (using name for ATM is discouraged, see osm wiki)
    UPDATE osm_poi_point
    SET (name, tags) = (
        COALESCE(tags -> 'operator', tags -> 'network'),
        tags || hstore('name', COALESCE(tags -> 'operator', tags -> 'network'))
    )
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_point.osm_ids))
      AND subclass = 'atm'
      AND name = ''
      AND COALESCE(tags -> 'operator', tags -> 'network') IS NOT NULL;

    -- Parcel locker without name 
    -- use either brand or operator and add ref if present
    -- (using name for parcel lockers is discouraged, see osm wiki)
    UPDATE osm_poi_point
    SET (name, tags) = (
        TRIM(CONCAT(COALESCE(tags -> 'brand', tags -> 'operator'), concat(' ', tags -> 'ref'))),
        tags || hstore('name', TRIM(CONCAT(COALESCE(tags -> 'brand', tags -> 'operator'), concat(' ', tags -> 'ref'))))
    )
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_point.osm_ids))
      AND subclass IN ('parcel_locker', 'charging_station')
      AND name = ''
      AND COALESCE(tags -> 'brand', tags -> 'operator') IS NOT NULL;

    UPDATE osm_poi_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_point.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_poi_point(TRUE);

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
        agg_stop IS DISTINCT FROM CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                THEN 1
        END;

    UPDATE osm_poi_point p
    SET
        agg_stop = (
        CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                     AND (r.rk IS NULL OR r.rk = 1)
                THEN 1
        END)
    FROM osm_poi_stop_rank r
    WHERE p.osm_id = r.osm_id AND
        agg_stop IS DISTINCT FROM (
        CASE
            WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
                     AND (r.rk IS NULL OR r.rk = 1)
                THEN 1
        END);

END;
$$ LANGUAGE plpgsql;

ALTER TABLE osm_poi_point
    ADD COLUMN IF NOT EXISTS agg_stop integer DEFAULT NULL;
SELECT update_osm_poi_point_agg();

-- Handle updates

CREATE OR REPLACE FUNCTION poi_point.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO poi_point.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

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

    -- Analyze tracking and source tables before performing update
    ANALYZE poi_point.osm_ids;
    ANALYZE osm_poi_point;

    PERFORM update_osm_poi_point(FALSE);
    REFRESH MATERIALIZED VIEW osm_poi_stop_centroid;
    REFRESH MATERIALIZED VIEW osm_poi_stop_rank;
    PERFORM update_osm_poi_point_agg();
    -- noinspection SqlWithoutWhere
    DELETE FROM poi_point.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM poi_point.updates;

    RAISE LOG 'Refresh poi_point done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_poi_point
    FOR EACH ROW
EXECUTE PROCEDURE poi_point.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_poi_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE poi_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON poi_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE poi_point.refresh();
