DROP TRIGGER IF EXISTS trigger_flag ON osm_aerodrome_label_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_aerodrome_label_point;
DROP TRIGGER IF EXISTS trigger_refresh ON aerodrome_label.updates;

-- Partial index for zoom 8/9 queries
CREATE INDEX IF NOT EXISTS osm_aerodrome_label_point_type_partial_idx
    ON osm_aerodrome_label_point USING gist (geometry)
    WHERE aerodrome_type = 'international'
      AND iata <> '';

CREATE SCHEMA IF NOT EXISTS aerodrome_label;

CREATE TABLE IF NOT EXISTS aerodrome_label.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc: osm_aerodrome_label_point -> osm_aerodrome_label_point
CREATE OR REPLACE FUNCTION update_aerodrome_label_point(full_update boolean) RETURNS void AS
$$
    UPDATE osm_aerodrome_label_point
    SET geometry = ST_Centroid(geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM aerodrome_label.osm_ids))
        AND ST_GeometryType(geometry) <> 'ST_Point';

    UPDATE osm_aerodrome_label_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM aerodrome_label.osm_ids))
        AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
        AND tags != update_tags(tags, geometry);

    UPDATE osm_aerodrome_label_point
    SET aerodrome_type=
       CASE
	    %%FIELD_MAPPING: class %%
	    ELSE 'other' END
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM aerodrome_label.osm_ids))
    AND aerodrome_type !=
       CASE
	    %%FIELD_MAPPING: class %%
	    ELSE 'other' END;
$$ LANGUAGE SQL;

SELECT update_aerodrome_label_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION aerodrome_label.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO aerodrome_label.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS aerodrome_label.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION aerodrome_label.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO aerodrome_label.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION aerodrome_label.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh aerodrome_label';

    -- Analyze tracking and source tables before performing update
    ANALYZE aerodrome_label.osm_ids;
    ANALYZE osm_aerodrome_label_point;

    PERFORM update_aerodrome_label_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM aerodrome_label.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM aerodrome_label.updates;

    RAISE LOG 'Refresh aerodrome_label done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_aerodrome_label_point
    FOR EACH ROW
    WHEN (pg_trigger_depth() < 1)
EXECUTE PROCEDURE aerodrome_label.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_aerodrome_label_point
    FOR EACH STATEMENT
    WHEN (pg_trigger_depth() < 1)
EXECUTE PROCEDURE aerodrome_label.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON aerodrome_label.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE aerodrome_label.refresh();
