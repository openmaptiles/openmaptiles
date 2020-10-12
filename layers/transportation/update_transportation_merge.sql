DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen3 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen4 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen5 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen6 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen7 CASCADE;


DROP TRIGGER IF EXISTS trigger_flag_transportation ON osm_highway_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON transportation.updates;

-- Instead of using relations to find out the road names we
-- stitch together the touching ways with the same name
-- to allow for nice label rendering
-- Because this works well for roads that do not have relations as well


-- Improve performance of the sql in transportation_name/network_type.sql
CREATE INDEX IF NOT EXISTS osm_highway_linestring_highway_partial_idx
    ON osm_highway_linestring (highway)
    WHERE highway IN ('motorway', 'trunk', 'primary', 'construction');

-- etldoc: osm_highway_linestring ->  osm_transportation_merge_linestring
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring AS
(
SELECT (ST_Dump(geometry)).geom AS geometry,
       NULL::bigint AS osm_id,
       highway,
       construction,
       z_order
FROM (
         SELECT ST_LineMerge(ST_Collect(geometry)) AS geometry,
                highway,
                construction,
                min(z_order) AS z_order
         FROM osm_highway_linestring
         WHERE (highway IN ('motorway', 'trunk', 'primary') OR
                highway = 'construction' AND construction IN ('motorway', 'trunk', 'primary'))
           AND ST_IsValid(geometry)
         GROUP BY highway, construction
     ) AS highway_union
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_geometry_idx
    ON osm_transportation_merge_linestring USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_highway_partial_idx
    ON osm_transportation_merge_linestring (highway, construction)
    WHERE highway IN ('motorway', 'trunk', 'primary', 'construction');

-- etldoc: osm_transportation_merge_linestring -> osm_transportation_merge_linestring_gen3
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen3 AS
(
SELECT ST_Simplify(geometry, 120) AS geometry, osm_id, highway, construction, z_order
FROM osm_transportation_merge_linestring
WHERE highway IN ('motorway', 'trunk', 'primary')
   OR highway = 'construction' AND construction IN ('motorway', 'trunk', 'primary')
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen3_geometry_idx
    ON osm_transportation_merge_linestring_gen3 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen3_highway_partial_idx
    ON osm_transportation_merge_linestring_gen3 (highway, construction)
    WHERE highway IN ('motorway', 'trunk', 'primary', 'construction');

-- etldoc: osm_transportation_merge_linestring_gen3 -> osm_transportation_merge_linestring_gen4
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen4 AS
(
SELECT ST_Simplify(geometry, 200) AS geometry, osm_id, highway, construction, z_order
FROM osm_transportation_merge_linestring_gen3
WHERE (highway IN ('motorway', 'trunk', 'primary') OR
       highway = 'construction' AND construction IN ('motorway', 'trunk', 'primary'))
  AND ST_Length(geometry) > 50
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen4_geometry_idx
    ON osm_transportation_merge_linestring_gen4 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen4_highway_partial_idx
    ON osm_transportation_merge_linestring_gen4 (highway, construction)
    WHERE highway IN ('motorway', 'trunk', 'primary', 'construction');

-- etldoc: osm_transportation_merge_linestring_gen4 -> osm_transportation_merge_linestring_gen5
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen5 AS
(
SELECT ST_Simplify(geometry, 500) AS geometry, osm_id, highway, construction, z_order
FROM osm_transportation_merge_linestring_gen4
WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND construction IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 100
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen5_geometry_idx
    ON osm_transportation_merge_linestring_gen5 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen5_highway_partial_idx
    ON osm_transportation_merge_linestring_gen5 (highway, construction)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_merge_linestring_gen5 -> osm_transportation_merge_linestring_gen6
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen6 AS
(
SELECT ST_Simplify(geometry, 1000) AS geometry, osm_id, highway, construction, z_order
FROM osm_transportation_merge_linestring_gen5
WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND construction IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 500
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen6_geometry_idx
    ON osm_transportation_merge_linestring_gen6 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen6_highway_partial_idx
    ON osm_transportation_merge_linestring_gen6 (highway, construction)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_merge_linestring_gen6 -> osm_transportation_merge_linestring_gen7
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen7 AS
(
SELECT ST_Simplify(geometry, 2000) AS geometry, osm_id, highway, construction, z_order
FROM osm_transportation_merge_linestring_gen6
WHERE (highway = 'motorway' OR highway = 'construction' AND construction = 'motorway')
  AND ST_Length(geometry) > 1000
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen7_geometry_idx
    ON osm_transportation_merge_linestring_gen7 USING gist (geometry);


-- Handle updates

CREATE SCHEMA IF NOT EXISTS transportation;

CREATE TABLE IF NOT EXISTS transportation.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION transportation.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation';
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen3;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen4;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen5;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen6;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen7;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.updates;

    RAISE LOG 'Refresh transportation done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag_transportation
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_highway_linestring
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON transportation.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation.refresh();
