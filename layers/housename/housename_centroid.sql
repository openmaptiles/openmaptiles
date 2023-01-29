DROP TRIGGER IF EXISTS trigger_flag ON osm_housename_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_housename_point;
DROP TRIGGER IF EXISTS trigger_refresh ON housename.updates;

CREATE SCHEMA IF NOT EXISTS housename;

CREATE TABLE IF NOT EXISTS housename.osm_ids
(
    osm_id bigint
);

-- etldoc: osm_housename_point -> osm_housename_point
CREATE OR REPLACE FUNCTION convert_housename_point(full_update boolean) RETURNS void AS
$$
    UPDATE osm_housename_point
    SET geometry =
            CASE
                WHEN ST_NPoints(ST_ConvexHull(geometry)) = ST_NPoints(geometry)
                    THEN ST_Centroid(geometry)
                ELSE ST_PointOnSurface(geometry)
                END
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM housename.osm_ids))
        AND ST_GeometryType(geometry) <> 'ST_Point'
        AND ST_IsValid(geometry);

    -- we don't need exact name just to know if it's present
    UPDATE osm_housename_point
    SET has_name = 
            CASE
                WHEN has_name = '' THEN '0'
                ELSE '1'
            END
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM housename.osm_ids));

$$ LANGUAGE SQL;

SELECT convert_housename_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION housename.store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE') THEN
        INSERT INTO housename.osm_ids VALUES (OLD.osm_id);
    ELSE
        INSERT INTO housename.osm_ids VALUES (NEW.osm_id);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS housename.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION housename.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO housename.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION housename.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh housename';
    PERFORM convert_housename_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM housename.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM housename.updates;

    RAISE LOG 'Refresh housename done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_housename_point
    FOR EACH ROW
EXECUTE PROCEDURE housename.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_housename_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE housename.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON housename.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE housename.refresh();
