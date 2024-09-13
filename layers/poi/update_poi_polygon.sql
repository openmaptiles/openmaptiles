DROP TRIGGER IF EXISTS trigger_flag ON osm_poi_polygon;
DROP TRIGGER IF EXISTS trigger_store ON osm_poi_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON poi_polygon.updates;

CREATE SCHEMA IF NOT EXISTS poi_polygon;

CREATE TABLE IF NOT EXISTS poi_polygon.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc:  osm_poi_polygon ->  osm_poi_polygon

CREATE OR REPLACE FUNCTION update_poi_polygon(full_update boolean) RETURNS void AS
$$
    UPDATE osm_poi_polygon
    SET geometry =
            CASE
                WHEN ST_NPoints(ST_ConvexHull(geometry)) = ST_NPoints(geometry)
                    THEN ST_Centroid(geometry)
                ELSE ST_PointOnSurface(geometry)
                END
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_polygon.osm_ids))
      AND ST_GeometryType(geometry) <> 'ST_Point'
      AND ST_IsValid(geometry);

    UPDATE osm_poi_polygon
    SET subclass = 'subway'
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_polygon.osm_ids))
      AND station = 'subway'
      AND subclass = 'station';

    UPDATE osm_poi_polygon
    SET subclass = 'halt'
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_polygon.osm_ids))
      AND funicular = 'yes'
      AND subclass = 'station';

    -- Parcel locker and charging_station without name 
    -- use either brand or operator and add ref if present
    -- (using name for parcel lockers is discouraged, see osm wiki)
    UPDATE osm_poi_polygon
    SET (name, tags) = (
        TRIM(CONCAT(COALESCE(tags -> 'brand', tags -> 'operator'), concat(' ', tags -> 'ref'))),
        tags || hstore('name', TRIM(CONCAT(COALESCE(tags -> 'brand', tags -> 'operator'), concat(' ', tags -> 'ref'))))
    )
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_polygon.osm_ids))
      AND subclass IN ('parcel_locker', 'charging_station')
      AND name = ''
      AND COALESCE(tags -> 'brand', tags -> 'operator') IS NOT NULL;

    UPDATE osm_poi_polygon
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM poi_polygon.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

$$ LANGUAGE SQL;

SELECT update_poi_polygon(true);

-- Handle updates

CREATE OR REPLACE FUNCTION poi_polygon.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO poi_polygon.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS poi_polygon.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION poi_polygon.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO poi_polygon.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION poi_polygon.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh poi_polygon';

    -- Analyze tracking and source tables before performing update
    ANALYZE poi_polygon.osm_ids;
    ANALYZE osm_poi_polygon;

    PERFORM update_poi_polygon(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM poi_polygon.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM poi_polygon.updates;

    RAISE LOG 'Refresh poi_polygon done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_poi_polygon
    FOR EACH ROW
EXECUTE PROCEDURE poi_polygon.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_poi_polygon
    FOR EACH STATEMENT
EXECUTE PROCEDURE poi_polygon.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON poi_polygon.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE poi_polygon.refresh();
