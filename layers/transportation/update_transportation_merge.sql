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

-- etldoc: osm_highway_linestring_gen_z11 ->  osm_transportation_merge_linestring_gen_z11
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen_z11 CASCADE;
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z11 AS
(
SELECT (ST_Dump(geometry)).geom AS geometry,
       NULL::bigint AS osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       z_order,
       bicycle,
       foot,
       horse,
       mtb_scale,
       layer
FROM (
         SELECT ST_LineMerge(ST_Collect(geometry)) AS geometry,
                highway,
                network,
                construction,
                is_bridge,
                is_tunnel,
                is_ford,
                min(z_order) AS z_order,
                bicycle,
                foot,
                horse,
                mtb_scale,
                layer
         FROM osm_highway_linestring_gen_z11
         WHERE ST_IsValid(geometry)
         GROUP BY highway, network, construction, is_bridge, is_tunnel, is_ford, bicycle, foot, horse, mtb_scale, layer
     ) AS highway_union
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z11_geometry_idx
    ON osm_transportation_merge_linestring_gen_z11 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z11 -> osm_transportation_merge_linestring_gen_z10
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen_z10 CASCADE;
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z10 AS
(
SELECT ST_Simplify(geometry, ZRes(12)) AS geometry,
       osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       z_order,
       bicycle,
       foot,
       horse,
       mtb_scale,
       layer
FROM osm_transportation_merge_linestring_gen_z11
WHERE highway NOT IN ('tertiary', 'tertiary_link')
      OR highway = 'construction' AND construction NOT IN ('tertiary', 'tertiary_link')
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z10_geometry_idx
    ON osm_transportation_merge_linestring_gen_z10 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z10 -> osm_transportation_merge_linestring_gen_z9
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen_z9 CASCADE;
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z9 AS
(
SELECT ST_Simplify(geometry, ZRes(11)) AS geometry,
       osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       z_order,
       bicycle,
       foot,
       horse,
       mtb_scale,
       layer
FROM osm_transportation_merge_linestring_gen_z10
WHERE highway NOT IN ('tertiary', 'tertiary_link')
      OR highway = 'construction' AND construction NOT IN ('tertiary', 'tertiary_link')
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z9_geometry_idx
    ON osm_transportation_merge_linestring_gen_z9 USING gist (geometry);

-- etldoc: osm_highway_linestring ->  osm_transportation_merge_linestring
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring CASCADE;
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring AS
(
SELECT (ST_Dump(geometry)).geom AS geometry,
       NULL::bigint AS osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       z_order
FROM (
         SELECT ST_LineMerge(ST_Collect(geometry)) AS geometry,
                highway,
                network,
                construction,
                is_bridge,
                is_tunnel,
                is_ford,
                min(z_order) AS z_order
         FROM osm_highway_linestring
         WHERE (highway IN ('motorway', 'trunk', 'primary') OR
                highway = 'construction' AND construction IN ('motorway', 'trunk', 'primary'))
           AND ST_IsValid(geometry)
         GROUP BY highway, network, construction, is_bridge, is_tunnel, is_ford
     ) AS highway_union
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_geometry_idx
    ON osm_transportation_merge_linestring USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring -> osm_transportation_merge_linestring_gen_z8
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen_z8 CASCADE;
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z8 AS
(
SELECT ST_Simplify(geometry, ZRes(10)) AS geometry,
       osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       z_order
FROM osm_transportation_merge_linestring
WHERE highway IN ('motorway', 'trunk', 'primary')
   OR highway = 'construction' AND construction IN ('motorway', 'trunk', 'primary')
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z8_geometry_idx
    ON osm_transportation_merge_linestring_gen_z8 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z7
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen_z7 CASCADE;
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z7 AS
(
SELECT ST_Simplify(geometry, ZRes(9)) AS geometry,
       osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       z_order
FROM osm_transportation_merge_linestring_gen_z8
WHERE (highway IN ('motorway', 'trunk', 'primary') OR
       highway = 'construction' AND construction IN ('motorway', 'trunk', 'primary'))
  AND ST_Length(geometry) > 50
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z7_geometry_idx
    ON osm_transportation_merge_linestring_gen_z7 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z7 -> osm_transportation_merge_linestring_gen_z6
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen_z6 CASCADE;
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z6 AS
(
SELECT ST_Simplify(geometry, ZRes(8)) AS geometry,
       osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       z_order
FROM osm_transportation_merge_linestring_gen_z7
WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND construction IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 100
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z6_geometry_idx
    ON osm_transportation_merge_linestring_gen_z6 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z6 -> osm_transportation_merge_linestring_gen_z5
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z5 AS
(
SELECT ST_Simplify(geometry, ZRes(7)) AS geometry,
       osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       z_order
FROM osm_transportation_merge_linestring_gen_z6
WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND construction IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 500
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z5_geometry_idx
    ON osm_transportation_merge_linestring_gen_z5 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z5 -> osm_transportation_merge_linestring_gen_z4
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z4 AS
(
SELECT ST_Simplify(geometry, ZRes(6)) AS geometry,
       osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       z_order
FROM osm_transportation_merge_linestring_gen_z5
WHERE (highway = 'motorway' OR highway = 'construction' AND construction = 'motorway')
  AND ST_Length(geometry) > 1000
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z4_geometry_idx
    ON osm_transportation_merge_linestring_gen_z4 USING gist (geometry);


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
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z8;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z7;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z6;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z5;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z4;
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
