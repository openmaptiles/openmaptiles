DROP TRIGGER IF EXISTS trigger_flag ON osm_state_point;
DROP TRIGGER IF EXISTS trigger_store ON osm_state_point;
DROP TRIGGER IF EXISTS trigger_refresh ON place_state.updates;

CREATE SCHEMA IF NOT EXISTS place_state;

CREATE TABLE IF NOT EXISTS place_state.osm_ids
(
    osm_id bigint PRIMARY KEY
);

-- etldoc: ne_10m_admin_1_states_provinces   -> osm_state_point
-- etldoc: osm_state_point                       -> osm_state_point

CREATE OR REPLACE FUNCTION update_osm_state_point(full_update boolean) RETURNS void AS
$$
    WITH important_state_point AS (
        SELECT osm.geometry,
               osm.osm_id,
               osm.name,
               COALESCE(NULLIF(osm.name_en, ''), ne.name) AS name_en,
               ne.scalerank,
               ne.labelrank,
               ne.datarank
        FROM ne_10m_admin_1_states_provinces AS ne,
             osm_state_point AS osm
        WHERE
          -- We only match whether the point is within the Natural Earth polygon
          -- because name matching is difficult
            ST_Within(osm.geometry, ne.geometry)
          -- We leave out leess important states
          AND ne.scalerank <= 6
          AND ne.labelrank <= 7
    )
    UPDATE osm_state_point AS osm
        -- Normalize both scalerank and labelrank into a ranking system from 1 to 6.
    SET "rank" = LEAST(6, CEILING((scalerank + labelrank + datarank) / 3.0))
    FROM important_state_point AS ne
    WHERE (full_update OR osm.osm_id IN (SELECT osm_id FROM place_state.osm_ids))
      AND rank IS NULL
      AND osm.osm_id = ne.osm_id;

    -- TODO: This shouldn't be necessary? The rank function makes something wrong...
    UPDATE osm_state_point AS osm
    SET "rank" = 1
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_state.osm_ids))
      AND "rank" = 0;

    DELETE FROM osm_state_point
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_state.osm_ids))
      AND "rank" IS NULL;

    UPDATE osm_state_point
    SET tags = update_tags(tags, geometry)
    WHERE (full_update OR osm_id IN (SELECT osm_id FROM place_state.osm_ids))
      AND COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL
      AND tags != update_tags(tags, geometry);

$$ LANGUAGE SQL;

SELECT update_osm_state_point(true);

-- Handle updates

CREATE OR REPLACE FUNCTION place_state.store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_state.osm_ids VALUES (NEW.osm_id) ON CONFLICT (osm_id) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS place_state.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION place_state.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO place_state.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION place_state.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh place_state rank';

    -- Analyze tracking and source tables before performing update
    ANALYZE place_state.osm_ids;
    ANALYZE osm_state_point;

    PERFORM update_osm_state_point(false);
    -- noinspection SqlWithoutWhere
    DELETE FROM place_state.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM place_state.updates;

    RAISE LOG 'Refresh place_state done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE
    ON osm_state_point
    FOR EACH ROW
EXECUTE PROCEDURE place_state.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE
    ON osm_state_point
    FOR EACH STATEMENT
EXECUTE PROCEDURE place_state.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON place_state.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE place_state.refresh();
