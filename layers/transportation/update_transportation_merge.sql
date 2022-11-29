DROP TRIGGER IF EXISTS trigger_osm_transportation_merge_linestring_gen_z8 ON osm_transportation_merge_linestring_gen_z8;
DROP TRIGGER IF EXISTS trigger_store_transportation_highway_linestring_gen_z9 ON osm_transportation_merge_linestring_gen_z9;
DROP TRIGGER IF EXISTS trigger_flag_transportation_z9 ON osm_transportation_merge_linestring_gen_z9;
DROP TRIGGER IF EXISTS trigger_refresh_z8 ON transportation.updates_z9;
DROP TRIGGER IF EXISTS trigger_osm_transportation_merge_linestring_gen_z11 ON osm_transportation_merge_linestring_gen_z11;
DROP TRIGGER IF EXISTS trigger_store_transportation_highway_linestring_gen_z11 ON osm_highway_linestring_gen_z11;
DROP TRIGGER IF EXISTS trigger_flag_transportation_z11 ON osm_highway_linestring_gen_z11;
DROP TRIGGER IF EXISTS trigger_refresh_z11 ON transportation.updates_z11;

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
    tags || get_basic_names(tags, geometry) AS tags,
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
        transportation_name_tags(hl.geometry, hl.tags, hl.name, hl.name_en, hl.name_de) AS tags,
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
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_name_ref_idx ON osm_transportation_name_network (coalesce(tags->'name', ''), coalesce(ref, ''));
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_geometry_idx ON osm_transportation_name_network USING gist (geometry);

-- Improve performance of the sql in transportation/update_route_member.sql
CREATE INDEX IF NOT EXISTS osm_highway_linestring_highway_partial_idx
    ON osm_highway_linestring (highway)
    WHERE highway IN ('motorway', 'trunk');


-- etldoc: osm_highway_linestring_gen_z11 ->  osm_transportation_merge_linestring_gen_z11
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z11(
    geometry geometry,
    id SERIAL PRIMARY KEY,
    osm_id bigint,
    highway character varying,
    network character varying,
    construction character varying,
    is_bridge boolean,
    is_tunnel boolean,
    is_ford boolean,
    expressway boolean,
    z_order integer,
    bicycle character varying,
    foot character varying,
    horse character varying,
    mtb_scale character varying,
    sac_scale character varying,
    access text,
    toll boolean,
    layer integer
);

INSERT INTO osm_transportation_merge_linestring_gen_z11(geometry, osm_id, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, z_order, bicycle, foot, horse, mtb_scale, sac_scale, access, toll, layer)
SELECT (ST_Dump(ST_LineMerge(ST_Collect(geometry)))).geom AS geometry,
       NULL::bigint AS osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       expressway,
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
GROUP BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, bicycle, foot, horse, mtb_scale, sac_scale, access, toll, layer
;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z11_geometry_idx
    ON osm_transportation_merge_linestring_gen_z11 USING gist (geometry);


CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z10
    (LIKE osm_transportation_merge_linestring_gen_z11);

CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z9
    (LIKE osm_transportation_merge_linestring_gen_z10);


CREATE OR REPLACE FUNCTION insert_transportation_merge_linestring_gen_z10(update_id bigint) RETURNS void AS
$$
BEGIN
    DELETE FROM osm_transportation_merge_linestring_gen_z10
    WHERE update_id IS NULL OR id = update_id;

    -- etldoc: osm_transportation_merge_linestring_gen_z11 -> osm_transportation_merge_linestring_gen_z10
    INSERT INTO osm_transportation_merge_linestring_gen_z10
    SELECT ST_Simplify(geometry, ZRes(12)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        is_bridge,
        is_tunnel,
        is_ford,
        expressway,
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
    WHERE (update_id IS NULL OR id = update_id)
        AND highway NOT IN ('tertiary', 'tertiary_link', 'busway', 'bus_guideway')
        AND construction NOT IN ('tertiary', 'tertiary_link', 'busway', 'bus_guideway')
    ;

    DELETE FROM osm_transportation_merge_linestring_gen_z9
    WHERE update_id IS NULL OR id = update_id;

    -- etldoc: osm_transportation_merge_linestring_gen_z10 -> osm_transportation_merge_linestring_gen_z9
    INSERT INTO osm_transportation_merge_linestring_gen_z9
    SELECT ST_Simplify(geometry, ZRes(11)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        is_bridge,
        is_tunnel,
        is_ford,
        expressway,
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
    WHERE (update_id IS NULL OR id = update_id)
    ;
END;
$$ LANGUAGE plpgsql;

SELECT insert_transportation_merge_linestring_gen_z10(NULL);

CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z10_geometry_idx
    ON osm_transportation_merge_linestring_gen_z10 USING gist (geometry);
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z10_id_idx
    ON osm_transportation_merge_linestring_gen_z10(id);

CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z9_geometry_idx
    ON osm_transportation_merge_linestring_gen_z9 USING gist (geometry);
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z9_id_idx
    ON osm_transportation_merge_linestring_gen_z9(id);


-- etldoc: osm_transportation_merge_linestring_gen_z9 -> osm_transportation_merge_linestring_gen_z8
CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z8(
    geometry geometry,
    id SERIAL PRIMARY KEY,
    osm_id bigint,
    highway character varying,
    network character varying,
    construction character varying,
    is_bridge boolean,
    is_tunnel boolean,
    is_ford boolean,
    expressway boolean,
    z_order integer
);

INSERT INTO osm_transportation_merge_linestring_gen_z8(geometry, osm_id, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, z_order)
SELECT ST_Simplify(ST_LineMerge(ST_Collect(geometry)), ZRes(10)) AS geometry,
       NULL::bigint AS osm_id,
       highway,
       network,
       construction,
       is_bridge,
       is_tunnel,
       is_ford,
       expressway,
       min(z_order) as z_order
FROM osm_transportation_merge_linestring_gen_z9
WHERE (highway IN ('motorway', 'trunk', 'primary') OR
       construction IN ('motorway', 'trunk', 'primary'))
       AND ST_IsValid(geometry)
       AND access IS NULL
GROUP BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway
;
CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z8_geometry_idx
    ON osm_transportation_merge_linestring_gen_z8 USING gist (geometry);

CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z7
    (LIKE osm_transportation_merge_linestring_gen_z8);

CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z6
    (LIKE osm_transportation_merge_linestring_gen_z7);

CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z5
    (LIKE osm_transportation_merge_linestring_gen_z6);

CREATE TABLE IF NOT EXISTS osm_transportation_merge_linestring_gen_z4
    (LIKE osm_transportation_merge_linestring_gen_z5);


CREATE OR REPLACE FUNCTION insert_transportation_merge_linestring_gen_z7(update_id bigint) RETURNS void AS
$$
BEGIN
    DELETE FROM osm_transportation_merge_linestring_gen_z7
    WHERE update_id IS NULL OR id = update_id;

    -- etldoc: osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z7
    INSERT INTO osm_transportation_merge_linestring_gen_z7
    SELECT ST_Simplify(geometry, ZRes(9)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        is_bridge,
        is_tunnel,
        is_ford,
        expressway,
        z_order
    FROM osm_transportation_merge_linestring_gen_z8
        -- Current view: motorway/trunk/primary
    WHERE
        (update_id IS NULL OR id = update_id) AND
        ST_Length(geometry) > 50;

    DELETE FROM osm_transportation_merge_linestring_gen_z6
    WHERE update_id IS NULL OR id = update_id;

    -- etldoc: osm_transportation_merge_linestring_gen_z7 -> osm_transportation_merge_linestring_gen_z6
    INSERT INTO osm_transportation_merge_linestring_gen_z6
    SELECT ST_Simplify(geometry, ZRes(8)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        is_bridge,
        is_tunnel,
        is_ford,
        expressway,
        z_order
    FROM osm_transportation_merge_linestring_gen_z7
    WHERE
        (update_id IS NULL OR id = update_id) AND
        (highway IN ('motorway', 'trunk') OR construction IN ('motorway', 'trunk')) AND
        ST_Length(geometry) > 100;

    DELETE FROM osm_transportation_merge_linestring_gen_z5
    WHERE update_id IS NULL OR id = update_id;

    -- etldoc: osm_transportation_merge_linestring_gen_z6 -> osm_transportation_merge_linestring_gen_z5
    INSERT INTO osm_transportation_merge_linestring_gen_z5
    SELECT ST_Simplify(geometry, ZRes(7)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        is_bridge,
        is_tunnel,
        is_ford,
        expressway,
        z_order
    FROM osm_transportation_merge_linestring_gen_z6
    WHERE
        (update_id IS NULL OR id = update_id) AND
        -- Current view: all motorways and trunks of national-importance
        (highway = 'motorway'
            OR construction = 'motorway'
            -- Allow trunk roads that are part of a nation's most important route network to show at z4
            OR (highway = 'trunk' AND osm_national_network(network))
        ) AND
        ST_Length(geometry) > 500;

    DELETE FROM osm_transportation_merge_linestring_gen_z4
    WHERE update_id IS NULL OR id = update_id;

    -- etldoc: osm_transportation_merge_linestring_gen_z5 -> osm_transportation_merge_linestring_gen_z4
    INSERT INTO osm_transportation_merge_linestring_gen_z4
    SELECT ST_Simplify(geometry, ZRes(6)) AS geometry,
        id,
        osm_id,
        highway,
        network,
        construction,
        is_bridge,
        is_tunnel,
        is_ford,
        expressway,
        z_order
    FROM osm_transportation_merge_linestring_gen_z5
    WHERE
        (update_id IS NULL OR id = update_id) AND
        osm_national_network(network) AND
        -- Current view: national-importance motorways and trunks
        ST_Length(geometry) > 1000;
END;
$$ LANGUAGE plpgsql;

SELECT insert_transportation_merge_linestring_gen_z7(NULL);

CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z7_geometry_idx
    ON osm_transportation_merge_linestring_gen_z7 USING gist (geometry);
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z7_id_idx
    ON osm_transportation_merge_linestring_gen_z7(id);

CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z6_geometry_idx
    ON osm_transportation_merge_linestring_gen_z6 USING gist (geometry);
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z6_id_idx
    ON osm_transportation_merge_linestring_gen_z6(id);

CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z5_geometry_idx
    ON osm_transportation_merge_linestring_gen_z5 USING gist (geometry);
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z5_id_idx
    ON osm_transportation_merge_linestring_gen_z5(id);

CREATE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z4_geometry_idx
    ON osm_transportation_merge_linestring_gen_z4 USING gist (geometry);
CREATE UNIQUE INDEX IF NOT EXISTS osm_transportation_merge_linestring_gen_z4_id_idx
    ON osm_transportation_merge_linestring_gen_z4(id);


-- Handle updates on
-- osm_highway_linestring_gen_z11 -> osm_transportation_merge_linestring_gen_z11

CREATE SCHEMA IF NOT EXISTS transportation;

CREATE TABLE IF NOT EXISTS transportation.changes_z11
(
    id serial PRIMARY KEY,
    is_old boolean,
    geometry geometry,
    osm_id bigint,
    highway character varying,
    network character varying,
    construction character varying,
    is_bridge boolean,
    is_tunnel boolean,
    is_ford boolean,
    expressway boolean,
    z_order integer,
    bicycle character varying,
    foot character varying,
    horse character varying,
    mtb_scale character varying,
    sac_scale character varying,
    access character varying,
    toll boolean,
    layer integer
);

CREATE OR REPLACE FUNCTION transportation.store_z11() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE' OR tg_op = 'UPDATE') THEN
        INSERT INTO transportation.changes_z11(is_old, geometry, osm_id, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, z_order, bicycle, foot, horse, mtb_scale, sac_scale, access, toll, layer)
        VALUES (true, old.geometry, old.osm_id, old.highway, old.network, old.construction, old.is_bridge, old.is_tunnel, old.is_ford, old.expressway, old.z_order, old.bicycle, old.foot, old.horse, old.mtb_scale, old.sac_scale,
            CASE
                WHEN old.access IN ('private', 'no') THEN 'no'
                ELSE NULL::text END,
            old.toll, old.layer);
    END IF;
    IF (tg_op = 'UPDATE' OR tg_op = 'INSERT') THEN
        INSERT INTO transportation.changes_z11(is_old, geometry, osm_id, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, z_order, bicycle, foot, horse, mtb_scale, sac_scale, access, toll, layer)
        VALUES (false, new.geometry, new.osm_id, new.highway, new.network, new.construction, new.is_bridge, new.is_tunnel, new.is_ford, new.expressway, new.z_order, new.bicycle, new.foot, new.horse, new.mtb_scale, new.sac_scale,
            CASE
                WHEN new.access IN ('private', 'no') THEN 'no'
                ELSE NULL::text END,
            new.toll, new.layer);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS transportation.updates_z11
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION transportation.flag_z11() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation.updates_z11(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation.refresh_z11() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation z11';

    -- Compact the change history to keep only the first and last version
    CREATE TEMP TABLE changes_compact AS
    SELECT
        *
    FROM ((
        SELECT DISTINCT ON (osm_id) *
        FROM transportation.changes_z11
        WHERE is_old
        ORDER BY osm_id,
                 id ASC
    ) UNION ALL (
        SELECT DISTINCT ON (osm_id) *
        FROM transportation.changes_z11
        WHERE NOT is_old
        ORDER BY osm_id,
                 id DESC
    )) AS t;

    -- Collect all original existing ways from impacted mmerge
    CREATE TEMP TABLE osm_highway_linestring_original AS
    SELECT DISTINCT ON (h.osm_id)
        NULL::integer AS id,
        NULL::boolean AS is_old,
        h.geometry,
        h.osm_id,
        h.highway,
        h.network,
        h.construction,
        h.is_bridge,
        h.is_tunnel,
        h.is_ford,
        h.expressway,
        h.z_order,
        h.bicycle,
        h.foot,
        h.horse,
        h.mtb_scale,
        h.sac_scale,
        h.access,
        h.toll,
        h.layer
    FROM
        changes_compact AS c
        JOIN osm_transportation_merge_linestring_gen_z11 AS m ON
             m.geometry && c.geometry
             AND m.highway IS NOT DISTINCT FROM c.highway
             AND m.network IS NOT DISTINCT FROM c.network
             AND m.construction IS NOT DISTINCT FROM c.construction
             AND m.is_bridge IS NOT DISTINCT FROM c.is_bridge
             AND m.is_tunnel IS NOT DISTINCT FROM c.is_tunnel
             AND m.is_ford IS NOT DISTINCT FROM c.is_ford
             AND m.expressway IS NOT DISTINCT FROM c.expressway
             AND m.bicycle IS NOT DISTINCT FROM c.bicycle
             AND m.foot IS NOT DISTINCT FROM c.foot
             AND m.horse IS NOT DISTINCT FROM c.horse
             AND m.mtb_scale IS NOT DISTINCT FROM c.mtb_scale
             AND m.sac_scale IS NOT DISTINCT FROM c.sac_scale
             AND m.access IS NOT DISTINCT FROM c.access
             AND m.toll IS NOT DISTINCT FROM c.toll
             AND m.layer IS NOT DISTINCT FROM c.layer
        JOIN osm_highway_linestring_gen_z11 AS h ON
             h.geometry && c.geometry
             AND h.osm_id NOT IN (SELECT osm_id FROM changes_compact)
             AND ST_Contains(m.geometry, h.geometry)
             AND h.highway IS NOT DISTINCT FROM m.highway
             AND h.network IS NOT DISTINCT FROM m.network
             AND h.construction IS NOT DISTINCT FROM m.construction
             AND h.is_bridge IS NOT DISTINCT FROM m.is_bridge
             AND h.is_tunnel IS NOT DISTINCT FROM m.is_tunnel
             AND h.is_ford IS NOT DISTINCT FROM m.is_ford
             AND h.expressway IS NOT DISTINCT FROM m.expressway
             AND h.bicycle IS NOT DISTINCT FROM m.bicycle
             AND h.foot IS NOT DISTINCT FROM m.foot
             AND h.horse IS NOT DISTINCT FROM m.horse
             AND h.mtb_scale IS NOT DISTINCT FROM m.mtb_scale
             AND h.sac_scale IS NOT DISTINCT FROM m.sac_scale
             AND CASE
                WHEN h.access IN ('private', 'no') THEN 'no'
                ELSE NULL::text END IS NOT DISTINCT FROM m.access
             AND h.toll IS NOT DISTINCT FROM m.toll
             AND h.layer IS NOT DISTINCT FROM m.layer
    ORDER BY
        h.osm_id
    ;

    DELETE
    FROM osm_transportation_merge_linestring_gen_z11 AS m
        USING changes_compact AS c
    WHERE
        m.geometry && c.geometry
        AND m.highway IS NOT DISTINCT FROM c.highway
        AND m.network IS NOT DISTINCT FROM c.network
        AND m.construction IS NOT DISTINCT FROM c.construction
        AND m.is_bridge IS NOT DISTINCT FROM c.is_bridge
        AND m.is_tunnel IS NOT DISTINCT FROM c.is_tunnel
        AND m.is_ford IS NOT DISTINCT FROM c.is_ford
        AND m.expressway IS NOT DISTINCT FROM c.expressway
        AND m.bicycle IS NOT DISTINCT FROM c.bicycle
        AND m.foot IS NOT DISTINCT FROM c.foot
        AND m.horse IS NOT DISTINCT FROM c.horse
        AND m.mtb_scale IS NOT DISTINCT FROM c.mtb_scale
        AND m.sac_scale IS NOT DISTINCT FROM c.sac_scale
        AND m.access IS NOT DISTINCT FROM c.access
        AND m.toll IS NOT DISTINCT FROM c.toll
        AND m.layer IS NOT DISTINCT FROM c.layer
    ;

    INSERT INTO osm_transportation_merge_linestring_gen_z11(geometry, osm_id, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, z_order, bicycle, foot, horse, mtb_scale, sac_scale, access, toll, layer)
    SELECT (ST_Dump(ST_LineMerge(ST_Collect(geometry)))).geom AS geometry,
        NULL::bigint AS osm_id,
        highway,
        network,
        construction,
        is_bridge,
        is_tunnel,
        is_ford,
        expressway,
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
    FROM ((
        SELECT * FROM osm_highway_linestring_original
    ) UNION ALL (
        -- New or updated ways
        SELECT
            *
        FROM
            changes_compact
        WHERE
            NOT is_old
    )) AS t
    GROUP BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, bicycle, foot, horse, mtb_scale, sac_scale, access, toll, layer
    ;

    DROP TABLE osm_highway_linestring_original;
    DROP TABLE changes_compact;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.changes_z11;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.updates_z11;

    RAISE LOG 'Refresh transportation z11 done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_store_transportation_highway_linestring_gen_z11
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_highway_linestring_gen_z11
    FOR EACH ROW
EXECUTE PROCEDURE transportation.store_z11();

CREATE TRIGGER trigger_flag_transportation_z11
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_highway_linestring_gen_z11
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation.flag_z11();

CREATE CONSTRAINT TRIGGER trigger_refresh_z11
    AFTER INSERT
    ON transportation.updates_z11
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation.refresh_z11();


-- Handle updates on
-- osm_transportation_merge_linestring_gen_z11 -> osm_transportation_merge_linestring_gen_z10
-- osm_transportation_merge_linestring_gen_z11 -> osm_transportation_merge_linestring_gen_z9


CREATE OR REPLACE FUNCTION transportation.merge_linestring_gen_refresh_z10() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE') THEN
        DELETE FROM osm_transportation_merge_linestring_gen_z10 WHERE id = old.id;
        DELETE FROM osm_transportation_merge_linestring_gen_z9 WHERE id = old.id;
    END IF;

    IF (tg_op = 'UPDATE' OR tg_op = 'INSERT') THEN
        PERFORM insert_transportation_merge_linestring_gen_z10(new.id);
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_osm_transportation_merge_linestring_gen_z11
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_merge_linestring_gen_z11
    FOR EACH ROW
EXECUTE PROCEDURE transportation.merge_linestring_gen_refresh_z10();


-- Handle updates on
-- osm_transportation_merge_linestring_gen_z9 -> osm_transportation_merge_linestring_gen_z8


CREATE TABLE IF NOT EXISTS transportation.changes_z9
(
    is_old boolean,
    geometry geometry,
    id bigint,
    highway character varying,
    network character varying,
    construction character varying,
    is_bridge boolean,
    is_tunnel boolean,
    is_ford boolean,
    expressway boolean,
    z_order integer
);

CREATE OR REPLACE FUNCTION transportation.store_z9() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE' OR tg_op = 'UPDATE') THEN
        INSERT INTO transportation.changes_z9(is_old, geometry, id, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, z_order)
        VALUES (true, old.geometry, old.id, old.highway, old.network, old.construction, old.is_bridge, old.is_tunnel, old.is_ford, old.expressway, old.z_order);
    END IF;
    IF (tg_op = 'UPDATE' OR tg_op = 'INSERT') THEN
        INSERT INTO transportation.changes_z9(is_old, geometry, id, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, z_order)
        VALUES (false, new.geometry, new.id, new.highway, new.network, new.construction, new.is_bridge, new.is_tunnel, new.is_ford, new.expressway, new.z_order);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS transportation.updates_z9
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION transportation.flag_z9() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation.updates_z9(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation.refresh_z8() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation z9';

    -- Compact the change history to keep only the first and last version
    CREATE TEMP TABLE changes_compact AS
    SELECT
        *
    FROM ((
        SELECT DISTINCT ON (id) *
        FROM transportation.changes_z9
        WHERE is_old
        ORDER BY id,
                 id ASC
    ) UNION ALL (
        SELECT DISTINCT ON (id) *
        FROM transportation.changes_z9
        WHERE NOT is_old
        ORDER BY id,
                 id DESC
    )) AS t;

    -- Collect all original existing ways from impacted mmerge
    CREATE TEMP TABLE osm_highway_linestring_original AS
    SELECT DISTINCT ON (h.id)
        NULL::boolean AS is_old,
        h.geometry,
        h.id,
        h.highway,
        h.network,
        h.construction,
        h.is_bridge,
        h.is_tunnel,
        h.is_ford,
        h.expressway,
        h.z_order
    FROM
        changes_compact AS c
        JOIN osm_transportation_merge_linestring_gen_z8 AS m ON
             m.geometry && c.geometry
             AND m.highway IS NOT DISTINCT FROM c.highway
             AND m.network IS NOT DISTINCT FROM c.network
             AND m.construction IS NOT DISTINCT FROM c.construction
             AND m.is_bridge IS NOT DISTINCT FROM c.is_bridge
             AND m.is_tunnel IS NOT DISTINCT FROM c.is_tunnel
             AND m.is_ford IS NOT DISTINCT FROM c.is_ford
             AND m.expressway IS NOT DISTINCT FROM c.expressway
        JOIN osm_transportation_merge_linestring_gen_z9 AS h ON
             h.geometry && c.geometry
             AND h.id NOT IN (SELECT id FROM changes_compact)
             AND ST_Contains(m.geometry, h.geometry)
             AND h.highway IS NOT DISTINCT FROM m.highway
             AND h.network IS NOT DISTINCT FROM m.network
             AND h.construction IS NOT DISTINCT FROM m.construction
             AND h.is_bridge IS NOT DISTINCT FROM m.is_bridge
             AND h.is_tunnel IS NOT DISTINCT FROM m.is_tunnel
             AND h.is_ford IS NOT DISTINCT FROM m.is_ford
             AND h.expressway IS NOT DISTINCT FROM m.expressway
    ORDER BY
        h.id
    ;

    DELETE
    FROM osm_transportation_merge_linestring_gen_z8 AS m
        USING changes_compact AS c
    WHERE
        m.geometry && c.geometry
        AND m.highway IS NOT DISTINCT FROM c.highway
        AND m.network IS NOT DISTINCT FROM c.network
        AND m.construction IS NOT DISTINCT FROM c.construction
        AND m.is_bridge IS NOT DISTINCT FROM c.is_bridge
        AND m.is_tunnel IS NOT DISTINCT FROM c.is_tunnel
        AND m.is_ford IS NOT DISTINCT FROM c.is_ford
        AND m.expressway IS NOT DISTINCT FROM c.expressway
    ;

    INSERT INTO osm_transportation_merge_linestring_gen_z8(geometry, osm_id, highway, network, construction, is_bridge, is_tunnel, is_ford, expressway, z_order)
    SELECT (ST_Dump(ST_LineMerge(ST_Collect(geometry)))).geom AS geometry,
        NULL::bigint AS osm_id,
        highway,
        network,
        construction,
        is_bridge,
        is_tunnel,
        is_ford,
        expressway,
        min(z_order) as z_order
    FROM ((
        SELECT * FROM osm_highway_linestring_original
    ) UNION ALL (
        -- New or updated ways
        SELECT
            *
        FROM
            changes_compact
        WHERE
            NOT is_old
    )) AS t
    GROUP BY highway, network, construction, is_bridge, is_tunnel, is_ford, expressway
    ;

    DROP TABLE osm_highway_linestring_original;
    DROP TABLE changes_compact;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.changes_z9;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation.updates_z9;

    RAISE LOG 'Refresh transportation z9 done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_store_transportation_highway_linestring_gen_z9
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_merge_linestring_gen_z9
    FOR EACH ROW
EXECUTE PROCEDURE transportation.store_z9();

CREATE TRIGGER trigger_flag_transportation_z9
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_merge_linestring_gen_z9
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation.flag_z9();

CREATE CONSTRAINT TRIGGER trigger_refresh_z8
    AFTER INSERT
    ON transportation.updates_z9
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation.refresh_z8();


-- Handle updates on
-- osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z7
-- osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z6
-- osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z5
-- osm_transportation_merge_linestring_gen_z8 -> osm_transportation_merge_linestring_gen_z4


CREATE OR REPLACE FUNCTION transportation.merge_linestring_gen_refresh_z7() RETURNS trigger AS
$$
BEGIN
    IF (tg_op = 'DELETE') THEN
        DELETE FROM osm_transportation_merge_linestring_gen_z7 WHERE id = old.id;
        DELETE FROM osm_transportation_merge_linestring_gen_z6 WHERE id = old.id;
        DELETE FROM osm_transportation_merge_linestring_gen_z5 WHERE id = old.id;
        DELETE FROM osm_transportation_merge_linestring_gen_z4 WHERE id = old.id;
    END IF;

    IF (tg_op = 'UPDATE' OR tg_op = 'INSERT') THEN
        PERFORM insert_transportation_merge_linestring_gen_z7(new.id);
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_osm_transportation_merge_linestring_gen_z8
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_merge_linestring_gen_z8
    FOR EACH ROW
EXECUTE PROCEDURE transportation.merge_linestring_gen_refresh_z7();
