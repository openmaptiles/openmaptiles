DROP TRIGGER IF EXISTS trigger_flag_transportation ON osm_highway_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON transportation.updates;

-- Instead of using relations to find out the road names we
-- stitch together the touching ways with the same name
-- to allow for nice label rendering
-- Because this works well for roads that do not have relations as well

-- etldoc: osm_highway_linestring ->  osm_transportation_name_network
-- etldoc: osm_route_member ->  osm_transportation_name_network
CREATE TABLE IF NOT EXISTS osm_transportation_name_network AS
SELECT
    geometry,
    osm_id,
    name,
    name_en,
    name_de,
    tags,
    ref,
    highway,
    subclass,
    brunnel,
    "level",
    sac_scale,
    layer,
    indoor,
    network_type,
    route_1, route_2, route_3, route_4, route_5, route_6,
    z_order,
    route_rank
FROM (
    SELECT DISTINCT ON (hl.osm_id)
        hl.geometry,
        hl.osm_id,
        CASE WHEN length(hl.name) > 15 THEN osml10n_street_abbrev_all(hl.name) ELSE NULLIF(hl.name, '') END AS "name",
        CASE WHEN length(hl.name_en) > 15 THEN osml10n_street_abbrev_en(hl.name_en) ELSE NULLIF(hl.name_en, '') END AS "name_en",
        CASE WHEN length(hl.name_de) > 15 THEN osml10n_street_abbrev_de(hl.name_de) ELSE NULLIF(hl.name_de, '') END AS "name_de",
        slice_language_tags(hl.tags) AS tags,
        rm1.network_type,
        CASE
            WHEN rm1.network_type IS NOT NULL AND rm1.ref::text <> ''
                THEN rm1.ref::text
            ELSE NULLIF(hl.ref, '')
            END AS ref,
        hl.highway,
        NULLIF(hl.construction, '') AS subclass,
        brunnel(hl.is_bridge, hl.is_tunnel, hl.is_ford) AS brunnel,
        sac_scale,
        CASE WHEN highway IN ('footway', 'steps') THEN layer END AS layer,
        CASE WHEN highway IN ('footway', 'steps') THEN level END AS level,
        CASE WHEN highway IN ('footway', 'steps') THEN indoor END AS indoor,
        NULLIF(rm1.network, '') || '=' || COALESCE(rm1.ref, '') AS route_1,
        NULLIF(rm2.network, '') || '=' || COALESCE(rm2.ref, '') AS route_2,
        NULLIF(rm3.network, '') || '=' || COALESCE(rm3.ref, '') AS route_3,
        NULLIF(rm4.network, '') || '=' || COALESCE(rm4.ref, '') AS route_4,
        NULLIF(rm5.network, '') || '=' || COALESCE(rm5.ref, '') AS route_5,
        NULLIF(rm6.network, '') || '=' || COALESCE(rm6.ref, '') AS route_6,
        hl.z_order,
        LEAST(rm1.rank, rm2.rank, rm3.rank, rm4.rank, rm5.rank, rm6.rank) AS route_rank
    FROM osm_highway_linestring hl
            LEFT OUTER JOIN osm_route_member rm1 ON rm1.member = hl.osm_id AND rm1.concurrency_index=1
            LEFT OUTER JOIN osm_route_member rm2 ON rm2.member = hl.osm_id AND rm2.concurrency_index=2
            LEFT OUTER JOIN osm_route_member rm3 ON rm3.member = hl.osm_id AND rm3.concurrency_index=3
            LEFT OUTER JOIN osm_route_member rm4 ON rm4.member = hl.osm_id AND rm4.concurrency_index=4
            LEFT OUTER JOIN osm_route_member rm5 ON rm5.member = hl.osm_id AND rm5.concurrency_index=5
            LEFT OUTER JOIN osm_route_member rm6 ON rm6.member = hl.osm_id AND rm6.concurrency_index=6
    WHERE (hl.name <> '' OR hl.ref <> '' OR rm1.ref <> '' OR rm1.network <> '')
      AND hl.highway <> ''
) AS t;
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_name_network_osm_id_idx ON osm_transportation_name_network (osm_id);
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_name_ref_idx ON osm_transportation_name_network (coalesce(name, ''), coalesce(ref, ''));
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_geometry_idx ON osm_transportation_name_network USING gist (geometry);

-- Improve performance of the sql in transportation/update_route_member.sql
CREATE INDEX IF NOT EXISTS osm_highway_linestring_highway_partial_idx
    ON osm_highway_linestring (highway)
    WHERE highway IN ('motorway', 'trunk');

-- etldoc: osm_highway_linestring_gen_z11 ->  osm_transportation_merge_linestring_gen_z11
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_merge_linestring_gen_z11 CASCADE;
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z11 AS
(
SELECT (ST_Dump(ST_LineMerge(ST_Collect(geometry)))).geom AS geometry,
       NULL::bigint AS osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       min(z_order) as z_order,
       bicycle,
       foot,
       horse,
       mtb_scale,
       sac_scale,
       CASE
           WHEN access IN ('private', 'no') THEN 'no'
           ELSE NULL::text END AS access,
       toll,
       layer
FROM osm_highway_linestring_gen_z11
-- mapping.yaml pre-filter: motorway/trunk/primary/secondary/tertiary, with _link variants, construction, ST_IsValid()
GROUP BY highway, network, construction, is_bridge, is_tunnel, is_ford, bicycle, foot, horse, mtb_scale, sac_scale, access, toll, layer
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z11_geometry_idx
    ON osm_transportation_merge_linestring_gen_z11 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z11 -> osm_transportation_merge_linestring_gen_z10
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
       sac_scale,
       access,
       toll,
       layer
FROM osm_transportation_merge_linestring_gen_z11
WHERE highway NOT IN ('tertiary', 'tertiary_link', 'busway')
      AND construction NOT IN ('tertiary', 'tertiary_link', 'busway')
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z10_geometry_idx
    ON osm_transportation_merge_linestring_gen_z10 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z10 -> osm_transportation_merge_linestring_gen_z9
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
       sac_scale,
       access,
       toll,
       layer
FROM osm_transportation_merge_linestring_gen_z10
     -- Current view: motorway/primary/secondary, with _link variants and construction 
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z9_geometry_idx
    ON osm_transportation_merge_linestring_gen_z9 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z9 ->  osm_transportation_merge_linestring_gen_z8
CREATE MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z8 AS
(
SELECT ST_Simplify(ST_LineMerge(ST_Collect(geometry)), ZRes(10)) AS geometry,
       NULL::bigint AS osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       min(z_order) as z_order
FROM osm_transportation_merge_linestring_gen_z9
WHERE (highway IN ('motorway', 'trunk', 'primary') OR
       construction IN ('motorway', 'trunk', 'primary'))
       AND ST_IsValid(geometry)
       AND access IS NULL
GROUP BY highway, network, construction, is_bridge, is_tunnel, is_ford
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z8_geometry_idx
    ON osm_transportation_merge_linestring_gen_z8 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z7
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
     -- Current view: motorway/trunk/primary
WHERE ST_Length(geometry) > 50
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z7_geometry_idx
    ON osm_transportation_merge_linestring_gen_z7 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z7 -> osm_transportation_merge_linestring_gen_z6
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
WHERE (highway IN ('motorway', 'trunk') OR construction IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 100
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z6_geometry_idx
    ON osm_transportation_merge_linestring_gen_z6 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z6 -> osm_transportation_merge_linestring_gen_z5
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
WHERE ST_Length(geometry) > 500
     -- Current view: motorway/trunk
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z5_geometry_idx
    ON osm_transportation_merge_linestring_gen_z5 USING gist (geometry);

-- etldoc: osm_transportation_merge_linestring_gen_z5 -> osm_transportation_merge_linestring_gen_z4
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
WHERE (highway = 'motorway' OR construction = 'motorway')
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
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z11;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z10;
    REFRESH MATERIALIZED VIEW osm_transportation_merge_linestring_gen_z9;
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
