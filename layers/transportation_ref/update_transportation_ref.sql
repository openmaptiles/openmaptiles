-- etldoc: osm_highway_linestring ->  osm_transportation_ref_network
-- etldoc: osm_route_member ->  osm_transportation_ref_network
CREATE TABLE IF NOT EXISTS osm_transportation_ref_network AS
SELECT
    geometry,
    osm_id,
    highway,
    subclass,
    network,
    network_1, network_2, network_3, network_4, network_5, network_6,
    ref_1,     ref_2,     ref_3,     ref_4,     ref_5,     ref_6,
    z_order
FROM (
    SELECT hl.geometry,
        hl.highway AS highway,
        hl.osm_id AS osm_id,
        NULLIF(hl.construction, '') AS subclass,
        rm1.network_type as network,
        rm1.network AS network_1,
        rm2.network AS network_2,
        rm3.network AS network_3,
        rm4.network AS network_4,
        rm5.network AS network_5,
        rm6.network AS network_6,
        rm1.ref AS ref_1,
        rm2.ref AS ref_2,
        rm3.ref AS ref_3,
        rm4.ref AS ref_4,
        rm5.ref AS ref_5,
        rm6.ref AS ref_6,
        hl.z_order
    FROM osm_highway_linestring hl
            LEFT OUTER JOIN osm_route_member rm1 ON rm1.member = hl.osm_id AND rm1.concurrency_index=1
            LEFT OUTER JOIN osm_route_member rm2 ON rm2.member = hl.osm_id AND rm2.concurrency_index=2
            LEFT OUTER JOIN osm_route_member rm3 ON rm3.member = hl.osm_id AND rm3.concurrency_index=3
            LEFT OUTER JOIN osm_route_member rm4 ON rm4.member = hl.osm_id AND rm4.concurrency_index=4
            LEFT OUTER JOIN osm_route_member rm5 ON rm5.member = hl.osm_id AND rm5.concurrency_index=5
            LEFT OUTER JOIN osm_route_member rm6 ON rm6.member = hl.osm_id AND rm6.concurrency_index=6
    WHERE (hl.ref <> '' OR rm1.ref <> '')
) AS t;

CREATE INDEX IF NOT EXISTS osm_transportation_ref_osm_id_idx ON osm_transportation_ref_network (osm_id);
CREATE INDEX IF NOT EXISTS osm_transportation_ref_network_ref_idx ON osm_transportation_ref_network (
       coalesce(network_1, ''), coalesce(ref_1, ''),
       coalesce(network_2, ''), coalesce(ref_2, ''),
       coalesce(network_3, ''), coalesce(ref_3, ''),
       coalesce(network_4, ''), coalesce(ref_4, ''),
       coalesce(network_5, ''), coalesce(ref_5, ''),
       coalesce(network_6, ''), coalesce(ref_6, ''));
CREATE INDEX IF NOT EXISTS osm_transportation_ref_network_geometry_idx ON osm_transportation_ref_network USING gist (geometry);

-- etldoc: osm_transportation_ref_network ->  osm_transportation_ref_linestring
CREATE TABLE IF NOT EXISTS osm_transportation_ref_linestring AS
SELECT (ST_Dump(geometry)).geom AS geometry,
       highway,
       subclass,
       network,
       network_1, network_2, network_3, network_4, network_5, network_6,
       ref_1,     ref_2,     ref_3,     ref_4,     ref_5,     ref_6,
       z_order
FROM (
         SELECT ST_LineMerge(ST_Collect(geometry)) AS geometry,
                highway,
                subclass,
                network,
                network_1, network_2, network_3, network_4, network_5, network_6,
                ref_1,     ref_2,     ref_3,     ref_4,     ref_5,     ref_6,
                min(z_order) AS z_order
         FROM osm_transportation_ref_network
         GROUP BY highway, subclass, network,
                  network_1, ref_1,
                  network_2, ref_2,
                  network_3, ref_3,
                  network_4, ref_4,
                  network_5, ref_5,
                  network_6, ref_6
     ) AS highway_ref_union
;
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_network_ref_idx ON osm_transportation_ref_linestring (
       coalesce(network_1, ''), coalesce(ref_1, ''),
       coalesce(network_2, ''), coalesce(ref_2, ''),
       coalesce(network_3, ''), coalesce(ref_3, ''),
       coalesce(network_4, ''), coalesce(ref_4, ''),
       coalesce(network_5, ''), coalesce(ref_5, ''),
       coalesce(network_6, ''), coalesce(ref_6, ''));
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_geometry_idx ON osm_transportation_ref_linestring USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_highway_partial_idx
    ON osm_transportation_ref_linestring (highway, subclass)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_ref_linestring -> osm_transportation_ref_linestring_gen1
CREATE OR REPLACE VIEW osm_transportation_ref_linestring_gen1_view AS
SELECT ST_Simplify(geometry, 50) AS geometry,
       highway,
       subclass,
       network,
       network_1, network_2, network_3, network_4, network_5, network_6,
       ref_1,     ref_2,     ref_3,     ref_4,     ref_5,     ref_6,
       z_order
FROM osm_transportation_ref_linestring
WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND subclass IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 8000
;
CREATE TABLE IF NOT EXISTS osm_transportation_ref_linestring_gen1 AS
SELECT *
FROM osm_transportation_ref_linestring_gen1_view;
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen1_name_ref_idx ON osm_transportation_ref_linestring_gen1(
       coalesce(network_1, ref_1),
       coalesce(network_2, ref_2),
       coalesce(network_3, ref_3),
       coalesce(network_4, ref_4),
       coalesce(network_5, ref_5),
       coalesce(network_6, ref_6));
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen1_geometry_idx ON osm_transportation_ref_linestring_gen1 USING gist (geometry);
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen1_highway_partial_idx
    ON osm_transportation_ref_linestring_gen1 (highway, subclass)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_ref_linestring_gen1 -> osm_transportation_ref_linestring_gen2
CREATE OR REPLACE VIEW osm_transportation_ref_linestring_gen2_view AS
SELECT ST_Simplify(geometry, 120) AS geometry,
       highway,
       subclass,
       network,
       network_1, network_2, network_3, network_4, network_5, network_6,
       ref_1,     ref_2,     ref_3,     ref_4,     ref_5,     ref_6,
       z_order
FROM osm_transportation_ref_linestring_gen1
WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND subclass IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 14000
;
CREATE TABLE IF NOT EXISTS osm_transportation_ref_linestring_gen2 AS
SELECT *
FROM osm_transportation_ref_linestring_gen2_view;
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen2_network_ref_idx ON osm_transportation_ref_linestring_gen2(
       coalesce(network_1, ref_1),
       coalesce(network_2, ref_2),
       coalesce(network_3, ref_3),
       coalesce(network_4, ref_4),
       coalesce(network_5, ref_5),
       coalesce(network_6, ref_6));
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen2_geometry_idx ON osm_transportation_ref_linestring_gen2 USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen2_highway_partial_idx
    ON osm_transportation_ref_linestring_gen2 (highway, subclass)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_ref_linestring_gen2 -> osm_transportation_ref_linestring_gen3
CREATE OR REPLACE VIEW osm_transportation_ref_linestring_gen3_view AS
SELECT ST_Simplify(geometry, 200) AS geometry,
       highway,
       subclass,
       network,
       network_1, network_2, network_3, network_4, network_5, network_6,
       ref_1,     ref_2,     ref_3,     ref_4,     ref_5,     ref_6,
       z_order
FROM osm_transportation_ref_linestring_gen2
WHERE (highway = 'motorway' OR highway = 'construction' AND subclass = 'motorway')
  AND ST_Length(geometry) > 20000
;
CREATE TABLE IF NOT EXISTS osm_transportation_ref_linestring_gen3 AS
SELECT *
FROM osm_transportation_ref_linestring_gen3_view;
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen3_network_ref_idx ON osm_transportation_ref_linestring_gen3(
       coalesce(network_1, ref_1),
       coalesce(network_2, ref_2),
       coalesce(network_3, ref_3),
       coalesce(network_4, ref_4),
       coalesce(network_5, ref_5),
       coalesce(network_6, ref_6));
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen3_geometry_idx ON osm_transportation_ref_linestring_gen3 USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen3_highway_partial_idx
    ON osm_transportation_ref_linestring_gen3 (highway, subclass)
    WHERE highway IN ('motorway', 'construction');

-- etldoc: osm_transportation_ref_linestring_gen3 -> osm_transportation_ref_linestring_gen4
CREATE OR REPLACE VIEW osm_transportation_ref_linestring_gen4_view AS
SELECT ST_Simplify(geometry, 500) AS geometry,
       highway,
       subclass,
       network,
       network_1, network_2, network_3, network_4, network_5, network_6,
       ref_1,     ref_2,     ref_3,     ref_4,     ref_5,     ref_6,
       z_order
FROM osm_transportation_ref_linestring_gen3
WHERE (highway = 'motorway' OR highway = 'construction' AND subclass = 'motorway')
  AND ST_Length(geometry) > 20000
;
CREATE TABLE IF NOT EXISTS osm_transportation_ref_linestring_gen4 AS
SELECT *
FROM osm_transportation_ref_linestring_gen4_view;
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen4_network_ref_idx ON osm_transportation_ref_linestring_gen4(
       coalesce(network_1, ref_1),
       coalesce(network_2, ref_2),
       coalesce(network_3, ref_3),
       coalesce(network_4, ref_4),
       coalesce(network_5, ref_5),
       coalesce(network_6, ref_6));
CREATE INDEX IF NOT EXISTS osm_transportation_ref_linestring_gen4_geometry_idx ON osm_transportation_ref_linestring_gen4 USING gist (geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS transportation_ref;

-- Trigger to update "osm_transportation_ref_network" from "osm_route_member" and "osm_highway_linestring"

CREATE TABLE IF NOT EXISTS transportation_ref.network_changes
(
    osm_id bigint,
    UNIQUE (osm_id)
);

CREATE OR REPLACE FUNCTION transportation_ref.route_member_store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_ref.network_changes(osm_id)
    VALUES (CASE WHEN tg_op IN ('DELETE', 'UPDATE') THEN old.member ELSE new.member END)
    ON CONFLICT(osm_id) DO NOTHING;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_ref.highway_linestring_store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_ref.network_changes(osm_id)
    VALUES (CASE WHEN tg_op IN ('DELETE', 'UPDATE') THEN old.osm_id ELSE new.osm_id END)
    ON CONFLICT(osm_id) DO NOTHING;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS transportation_ref.updates_network
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);

CREATE OR REPLACE FUNCTION transportation_ref.flag_network() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_ref.updates_network(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_ref.refresh_network() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation_ref_network';
    -- update_osm_route_member() performed by transportation_name update

    -- REFRESH osm_transportation_ref_network
    DELETE
    FROM osm_transportation_ref_network AS n
        USING
            transportation_ref.network_changes AS c
    WHERE n.osm_id = c.osm_id;

    INSERT INTO osm_transportation_ref_network
    SELECT
        geometry,
        osm_id,
        highway,
        subclass,
        network,
        network_1, network_2, network_3, network_4, network_5, network_6,
        ref_1,     ref_2,     ref_3,     ref_4,     ref_5,     ref_6,
        z_order
    FROM (
        SELECT hl.geometry,
            hl.highway AS highway,
            hl.osm_id AS osm_id,
            NULLIF(hl.construction, '') AS subclass,
            rm1.network_type AS network,
            rm1.network AS network_1,
            rm2.network AS network_2,
            rm3.network AS network_3,
            rm4.network AS network_4,
            rm5.network AS network_5,
            rm6.network AS network_6,
            rm1.ref AS ref_1,
            rm2.ref AS ref_2,
            rm3.ref AS ref_3,
            rm4.ref AS ref_4,
            rm5.ref AS ref_5,
            rm6.ref AS ref_6,
            hl.z_order
        FROM osm_highway_linestring hl
            LEFT OUTER JOIN osm_route_member rm1 ON rm1.member = hl.osm_id AND rm1.concurrency_index=1
            LEFT OUTER JOIN osm_route_member rm2 ON rm2.member = hl.osm_id AND rm2.concurrency_index=2
            LEFT OUTER JOIN osm_route_member rm3 ON rm3.member = hl.osm_id AND rm3.concurrency_index=3
            LEFT OUTER JOIN osm_route_member rm4 ON rm4.member = hl.osm_id AND rm4.concurrency_index=4
            LEFT OUTER JOIN osm_route_member rm5 ON rm5.member = hl.osm_id AND rm5.concurrency_index=5
            LEFT OUTER JOIN osm_route_member rm6 ON rm6.member = hl.osm_id AND rm6.concurrency_index=6
        WHERE (hl.ref <> '' OR rm1.ref <> '')
          AND NULLIF(hl.highway, '') IS NOT NULL
    ) AS t;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_ref.network_changes;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_ref.updates_network;

    RAISE LOG 'Refresh transportation_ref network done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store_transportation_ref_route_member
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_route_member
    FOR EACH ROW
EXECUTE PROCEDURE transportation_ref.route_member_store();

CREATE TRIGGER trigger_store_transportation_ref_highway_linestring
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_highway_linestring
    FOR EACH ROW
EXECUTE PROCEDURE transportation_ref.highway_linestring_store();

CREATE TRIGGER trigger_flag_transportation_ref
    AFTER INSERT
    ON transportation_ref.network_changes
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation_ref.flag_network();

CREATE CONSTRAINT TRIGGER trigger_refresh_network_ref
    AFTER INSERT
    ON transportation_ref.updates_network
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation_ref.refresh_network();

/*

-- Trigger to update "osm_transportation_ref_linestring" from "osm_transportation_ref_network"

CREATE TABLE IF NOT EXISTS transportation_ref.ref_changes
(
    id serial PRIMARY KEY,
    is_old boolean,
    osm_id bigint,
    name character varying,
    name_en character varying,
    name_de character varying,
    ref character varying,
    highway character varying,
    subclass character varying,
    brunnel character varying,
    level integer,
    layer integer,
    indoor boolean,
    network_type route_network_type
);

CREATE OR REPLACE FUNCTION transportation_ref.ref_network_store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op IN ('DELETE', 'UPDATE'))
    THEN
        INSERT INTO transportation_name.name_changes(is_old, osm_id, name, name_en, name_de, ref, highway, subclass,
                                                     brunnel, level, layer, indoor, network_type)
        VALUES (TRUE, old.osm_id, old.name, old.name_en, old.name_de, old.ref, old.highway, old.subclass,
                old.brunnel, old.level, old.layer, old.indoor, old.network_type);
    END IF;
    IF (tg_op IN ('UPDATE', 'INSERT'))
    THEN
        INSERT INTO transportation_name.name_changes(is_old, osm_id, name, name_en, name_de, ref, highway, subclass,
                                                     brunnel, level, layer, indoor, network_type)
        VALUES (FALSE, new.osm_id, new.name, new.name_en, new.name_de, new.ref, new.highway, new.subclass,
                new.brunnel, new.level, new.layer, new.indoor, new.network_type);
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS transportation_name.updates_name
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION transportation_name.flag_name() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_name.updates_name(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_name.refresh_name() RETURNS trigger AS
$BODY$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation_name';

    -- REFRESH osm_transportation_name_linestring

    -- Compact the change history to keep only the first and last version, and then uniq version of row
    CREATE TEMP TABLE name_changes_compact AS
    SELECT DISTINCT ON (name, name_en, name_de, ref, highway, subclass, brunnel, level, layer, indoor, network_type)
        name,
        name_en,
        name_de,
        ref,
        highway,
        subclass,
        brunnel,
        level,
        layer,
        indoor,
        network_type,
        coalesce(name, ref) AS name_ref
    FROM ((
              SELECT DISTINCT ON (osm_id) *
              FROM transportation_name.name_changes
              WHERE is_old
              ORDER BY osm_id,
                       id ASC
          )
          UNION ALL
          (
              SELECT DISTINCT ON (osm_id) *
              FROM transportation_name.name_changes
              WHERE NOT is_old
              ORDER BY osm_id,
                       id DESC
          )) AS t;

    DELETE
    FROM osm_transportation_name_linestring AS n
        USING name_changes_compact AS c
    WHERE coalesce(n.name, '') = coalesce(c.name, '')
      AND coalesce(n.ref, '') = coalesce(c.ref, '')
      AND n.name_en IS NOT DISTINCT FROM c.name_en
      AND n.name_de IS NOT DISTINCT FROM c.name_de
      AND n.highway IS NOT DISTINCT FROM c.highway
      AND n.subclass IS NOT DISTINCT FROM c.subclass
      AND n.brunnel IS NOT DISTINCT FROM c.brunnel
      AND n.level IS NOT DISTINCT FROM c.level
      AND n.layer IS NOT DISTINCT FROM c.layer
      AND n.indoor IS NOT DISTINCT FROM c.indoor
      AND n.network IS NOT DISTINCT FROM c.network_type;

    INSERT INTO osm_transportation_name_linestring
    SELECT (ST_Dump(geometry)).geom AS geometry,
           NULL::bigint AS osm_id,
           name,
           name_en,
           name_de,
           tags || get_basic_names(tags, geometry) AS tags,
           ref,
           highway,
           subclass,
           brunnel,
           level,
           layer,
           indoor,
           network_type AS network,
           z_order
    FROM (
        SELECT ST_LineMerge(ST_Collect(n.geometry)) AS geometry,
            n.name,
            n.name_en,
            n.name_de,
            hstore(string_agg(nullif(slice_language_tags(tags ||
                                                         hstore(ARRAY ['name', n.name, 'name:en', n.name_en, 'name:de', n.name_de]))::text,
                                     ''), ',')) AS tags,
            n.ref,
            n.highway,
            n.subclass,
            n.brunnel,
            n.level,
            n.layer,
            n.indoor,
            n.network_type,
            min(n.z_order) AS z_order
        FROM osm_transportation_name_network AS n
            JOIN name_changes_compact AS c ON
                 coalesce(n.name, '') = coalesce(c.name, '')
             AND coalesce(n.ref, '') = coalesce(c.ref, '')
             AND n.name_en IS NOT DISTINCT FROM c.name_en
             AND n.name_de IS NOT DISTINCT FROM c.name_de
             AND n.highway IS NOT DISTINCT FROM c.highway
             AND n.subclass IS NOT DISTINCT FROM c.subclass
             AND n.brunnel IS NOT DISTINCT FROM c.brunnel
             AND n.level IS NOT DISTINCT FROM c.level
             AND n.layer IS NOT DISTINCT FROM c.layer
             AND n.indoor IS NOT DISTINCT FROM c.indoor
             AND n.network_type IS NOT DISTINCT FROM c.network_type
        GROUP BY n.name, n.name_en, n.name_de, n.ref, n.highway, n.subclass, n.brunnel, n.level, n.layer, n.indoor, n.network_type
    ) AS highway_union;

    -- REFRESH osm_transportation_name_linestring_gen1
    DELETE FROM osm_transportation_name_linestring_gen1 AS n
    USING name_changes_compact AS c
    WHERE
        coalesce(n.name, n.ref) = c.name_ref
        AND n.name IS NOT DISTINCT FROM c.name
        AND n.name_en IS NOT DISTINCT FROM c.name_en
        AND n.name_de IS NOT DISTINCT FROM c.name_de
        AND n.ref IS NOT DISTINCT FROM c.ref
        AND n.highway IS NOT DISTINCT FROM c.highway
        AND n.subclass IS NOT DISTINCT FROM c.subclass
        AND n.brunnel IS NOT DISTINCT FROM c.brunnel
        AND n.network IS NOT DISTINCT FROM c.network_type;

    INSERT INTO osm_transportation_name_linestring_gen1
    SELECT n.*
    FROM osm_transportation_name_linestring_gen1_view AS n
        JOIN name_changes_compact AS c ON
            coalesce(n.name, n.ref) = c.name_ref
            AND n.name IS NOT DISTINCT FROM c.name
            AND n.name_en IS NOT DISTINCT FROM c.name_en
            AND n.name_de IS NOT DISTINCT FROM c.name_de
            AND n.ref IS NOT DISTINCT FROM c.ref
            AND n.highway IS NOT DISTINCT FROM c.highway
            AND n.subclass IS NOT DISTINCT FROM c.subclass
            AND n.brunnel IS NOT DISTINCT FROM c.brunnel
            AND n.network IS NOT DISTINCT FROM c.network_type;

    -- REFRESH osm_transportation_name_linestring_gen2
    DELETE FROM osm_transportation_name_linestring_gen2 AS n
    USING name_changes_compact AS c
    WHERE
        coalesce(n.name, n.ref) = c.name_ref
        AND n.name IS NOT DISTINCT FROM c.name
        AND n.name_en IS NOT DISTINCT FROM c.name_en
        AND n.name_de IS NOT DISTINCT FROM c.name_de
        AND n.ref IS NOT DISTINCT FROM c.ref
        AND n.highway IS NOT DISTINCT FROM c.highway
        AND n.subclass IS NOT DISTINCT FROM c.subclass
        AND n.brunnel IS NOT DISTINCT FROM c.brunnel
        AND n.network IS NOT DISTINCT FROM c.network_type;

    INSERT INTO osm_transportation_name_linestring_gen2
    SELECT n.*
    FROM osm_transportation_name_linestring_gen2_view AS n
        JOIN name_changes_compact AS c ON
            coalesce(n.name, n.ref) = c.name_ref
            AND n.name IS NOT DISTINCT FROM c.name
            AND n.name_en IS NOT DISTINCT FROM c.name_en
            AND n.name_de IS NOT DISTINCT FROM c.name_de
            AND n.ref IS NOT DISTINCT FROM c.ref
            AND n.highway IS NOT DISTINCT FROM c.highway
            AND n.subclass IS NOT DISTINCT FROM c.subclass
            AND n.brunnel IS NOT DISTINCT FROM c.brunnel
            AND n.network IS NOT DISTINCT FROM c.network_type;

    -- REFRESH osm_transportation_name_linestring_gen3
    DELETE FROM osm_transportation_name_linestring_gen3 AS n
    USING name_changes_compact AS c
    WHERE
        coalesce(n.name, n.ref) = c.name_ref
        AND n.name IS NOT DISTINCT FROM c.name
        AND n.name_en IS NOT DISTINCT FROM c.name_en
        AND n.name_de IS NOT DISTINCT FROM c.name_de
        AND n.ref IS NOT DISTINCT FROM c.ref
        AND n.highway IS NOT DISTINCT FROM c.highway
        AND n.subclass IS NOT DISTINCT FROM c.subclass
        AND n.brunnel IS NOT DISTINCT FROM c.brunnel
        AND n.network IS NOT DISTINCT FROM c.network_type;

    INSERT INTO osm_transportation_name_linestring_gen3
    SELECT n.*
    FROM osm_transportation_name_linestring_gen3_view AS n
        JOIN name_changes_compact AS c ON
            coalesce(n.name, n.ref) = c.name_ref
            AND n.name IS NOT DISTINCT FROM c.name
            AND n.name_en IS NOT DISTINCT FROM c.name_en
            AND n.name_de IS NOT DISTINCT FROM c.name_de
            AND n.ref IS NOT DISTINCT FROM c.ref
            AND n.highway IS NOT DISTINCT FROM c.highway
            AND n.subclass IS NOT DISTINCT FROM c.subclass
            AND n.brunnel IS NOT DISTINCT FROM c.brunnel
            AND n.network IS NOT DISTINCT FROM c.network_type;

    -- REFRESH osm_transportation_name_linestring_gen4
    DELETE FROM osm_transportation_name_linestring_gen4 AS n
    USING name_changes_compact AS c
    WHERE
        coalesce(n.name, n.ref) = c.name_ref
        AND n.name IS NOT DISTINCT FROM c.name
        AND n.name_en IS NOT DISTINCT FROM c.name_en
        AND n.name_de IS NOT DISTINCT FROM c.name_de
        AND n.ref IS NOT DISTINCT FROM c.ref
        AND n.highway IS NOT DISTINCT FROM c.highway
        AND n.subclass IS NOT DISTINCT FROM c.subclass
        AND n.brunnel IS NOT DISTINCT FROM c.brunnel
        AND n.network IS NOT DISTINCT FROM c.network_type;

    INSERT INTO osm_transportation_name_linestring_gen4
    SELECT n.*
    FROM osm_transportation_name_linestring_gen4_view AS n
        JOIN name_changes_compact AS c ON
            coalesce(n.name, n.ref) = c.name_ref
            AND n.name IS NOT DISTINCT FROM c.name
            AND n.name_en IS NOT DISTINCT FROM c.name_en
            AND n.name_de IS NOT DISTINCT FROM c.name_de
            AND n.ref IS NOT DISTINCT FROM c.ref
            AND n.highway IS NOT DISTINCT FROM c.highway
            AND n.subclass IS NOT DISTINCT FROM c.subclass
            AND n.brunnel IS NOT DISTINCT FROM c.brunnel
            AND n.network IS NOT DISTINCT FROM c.network_type;

    DROP TABLE name_changes_compact;
    DELETE FROM transportation_name.name_changes;
    DELETE FROM transportation_name.updates_name;

    RAISE LOG 'Refresh transportation_name done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$BODY$
    LANGUAGE plpgsql;


CREATE TRIGGER trigger_store_transportation_name_network
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_name_network
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.name_network_store();

CREATE TRIGGER trigger_flag_name
    AFTER INSERT
    ON transportation_name.name_changes
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation_name.flag_name();

CREATE CONSTRAINT TRIGGER trigger_refresh_name
    AFTER INSERT
    ON transportation_name.updates_name
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.refresh_name();
*/
