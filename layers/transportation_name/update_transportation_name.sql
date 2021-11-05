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
    layer,
    indoor,
    network_type,
    route_1, route_2, route_3, route_4, route_5, route_6,
    z_order
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
        CASE WHEN highway IN ('footway', 'steps') THEN layer END AS layer,
        CASE WHEN highway IN ('footway', 'steps') THEN level END AS level,
        CASE WHEN highway IN ('footway', 'steps') THEN indoor END AS indoor,
        NULLIF(rm1.network, '') || '=' || COALESCE(rm1.ref, '') AS route_1,
        NULLIF(rm2.network, '') || '=' || COALESCE(rm2.ref, '') AS route_2,
        NULLIF(rm3.network, '') || '=' || COALESCE(rm3.ref, '') AS route_3,
        NULLIF(rm4.network, '') || '=' || COALESCE(rm4.ref, '') AS route_4,
        NULLIF(rm5.network, '') || '=' || COALESCE(rm5.ref, '') AS route_5,
        NULLIF(rm6.network, '') || '=' || COALESCE(rm6.ref, '') AS route_6,
        hl.z_order
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
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_osm_id_idx ON osm_transportation_name_network (osm_id);
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_name_ref_idx ON osm_transportation_name_network (coalesce(name, ''), coalesce(ref, ''));
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_geometry_idx ON osm_transportation_name_network USING gist (geometry);


-- etldoc: osm_transportation_name_network ->  osm_transportation_name_linestring
-- etldoc: osm_shipway_linestring ->  osm_transportation_name_linestring
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring AS
SELECT (ST_Dump(geometry)).geom AS geometry,
       name,
       name_en,
       name_de,
       tags || get_basic_names(tags, geometry) AS "tags",
       ref,
       highway,
       subclass,
       brunnel,
       "level",
       layer,
       indoor,
       network_type AS network,
       route_1, route_2, route_3, route_4, route_5, route_6,
       z_order
FROM (
         SELECT ST_LineMerge(ST_Collect(geometry)) AS geometry,
                name,
                name_en,
                name_de,
                tags || hstore( -- store results of osml10n_street_abbrev_* above
                               ARRAY ['name', name, 'name:en', name_en, 'name:de', name_de]) AS tags,
                ref,
                highway,
                subclass,
                CASE WHEN COUNT(*) = COUNT(brunnel) AND MAX(brunnel) = MIN(brunnel)
                     THEN MAX(brunnel)
                     ELSE NULL::text END AS brunnel,
                "level",
                layer,
                indoor,
                network_type,
                route_1, route_2, route_3, route_4, route_5, route_6,
                min(z_order) AS z_order
         FROM osm_transportation_name_network
         WHERE name <> '' OR ref <> ''
         GROUP BY name, name_en, name_de, tags, ref, highway, subclass, "level", layer, indoor, network_type,
                  route_1, route_2, route_3, route_4, route_5, route_6
         UNION ALL

         SELECT ST_LineMerge(ST_Collect(geometry)) AS geometry,
                CASE WHEN length(name) > 15 THEN osml10n_street_abbrev_all(name) ELSE NULLIF(name, '') END AS "name",
                CASE WHEN length(name_en) > 15 THEN osml10n_street_abbrev_en(name_en) ELSE NULLIF(name_en, '') END AS "name_en",
                CASE WHEN length(name_de) > 15 THEN osml10n_street_abbrev_de(name_de) ELSE NULLIF(name_de, '') END AS "name_de",
                slice_language_tags(tags) || hstore(ARRAY ['name', name, 'name:en', name_en, 'name:de', name_de]) AS tags,
                NULL AS ref,
                'shipway' AS highway,
                shipway AS subclass,
                NULL AS brunnel,
                NULL::int AS level,
                layer,
                NULL AS indoor,
                NULL AS network_type,
                NULL AS route_1,
                NULL AS route_2,
                NULL AS route_3,
                NULL AS route_4,
                NULL AS route_5,
                NULL AS route_6,
                min(z_order) AS z_order
         FROM osm_shipway_linestring
         WHERE name <> ''
         GROUP BY name, name_en, name_de, tags, subclass, "level", layer
     ) AS highway_union
;
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_name_ref_idx ON osm_transportation_name_linestring (coalesce(name, ''), coalesce(ref, ''));
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_geometry_idx ON osm_transportation_name_linestring USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_highway_partial_idx
    ON osm_transportation_name_linestring (highway, subclass)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_name_linestring -> osm_transportation_name_linestring_gen1
CREATE OR REPLACE VIEW osm_transportation_name_linestring_gen1_view AS
SELECT ST_Simplify(geometry, 50) AS geometry,
       name,
       name_en,
       name_de,
       tags,
       ref,
       highway,
       subclass,
       brunnel,
       network,
       route_1, route_2, route_3, route_4, route_5, route_6,
       z_order
FROM osm_transportation_name_linestring
WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND subclass IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 8000
;
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring_gen1 AS
SELECT *
FROM osm_transportation_name_linestring_gen1_view;
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen1_name_ref_idx ON osm_transportation_name_linestring_gen1((coalesce(name, ref)));
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen1_geometry_idx ON osm_transportation_name_linestring_gen1 USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen1_highway_partial_idx
    ON osm_transportation_name_linestring_gen1 (highway, subclass)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_name_linestring_gen1 -> osm_transportation_name_linestring_gen2
CREATE OR REPLACE VIEW osm_transportation_name_linestring_gen2_view AS
SELECT ST_Simplify(geometry, 120) AS geometry,
       name,
       name_en,
       name_de,
       tags,
       ref,
       highway,
       subclass,
       brunnel,
       network,
       route_1, route_2, route_3, route_4, route_5, route_6,
       z_order
FROM osm_transportation_name_linestring_gen1
WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND subclass IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 14000
;
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring_gen2 AS
SELECT *
FROM osm_transportation_name_linestring_gen2_view;
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen2_name_ref_idx ON osm_transportation_name_linestring_gen2((coalesce(name, ref)));
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen2_geometry_idx ON osm_transportation_name_linestring_gen2 USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen2_highway_partial_idx
    ON osm_transportation_name_linestring_gen2 (highway, subclass)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_name_linestring_gen2 -> osm_transportation_name_linestring_gen3
CREATE OR REPLACE VIEW osm_transportation_name_linestring_gen3_view AS
SELECT ST_Simplify(geometry, 200) AS geometry,
       name,
       name_en,
       name_de,
       tags,
       ref,
       highway,
       subclass,
       brunnel,
       network,
       route_1, route_2, route_3, route_4, route_5, route_6,
       z_order
FROM osm_transportation_name_linestring_gen2
WHERE (highway = 'motorway' OR highway = 'construction' AND subclass = 'motorway')
  AND ST_Length(geometry) > 20000
;
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring_gen3 AS
SELECT *
FROM osm_transportation_name_linestring_gen3_view;
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen3_name_ref_idx ON osm_transportation_name_linestring_gen3((coalesce(name, ref)));
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen3_geometry_idx ON osm_transportation_name_linestring_gen3 USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen3_highway_partial_idx
    ON osm_transportation_name_linestring_gen3 (highway, subclass)
    WHERE highway IN ('motorway', 'construction');

-- etldoc: osm_transportation_name_linestring_gen3 -> osm_transportation_name_linestring_gen4
CREATE OR REPLACE VIEW osm_transportation_name_linestring_gen4_view AS
SELECT ST_Simplify(geometry, 500) AS geometry,
       name,
       name_en,
       name_de,
       tags,
       ref,
       highway,
       subclass,
       brunnel,
       network,
       route_1, route_2, route_3, route_4, route_5, route_6,
       z_order
FROM osm_transportation_name_linestring_gen3
WHERE (highway = 'motorway' OR highway = 'construction' AND subclass = 'motorway')
  AND ST_Length(geometry) > 20000
;
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring_gen4 AS
SELECT *
FROM osm_transportation_name_linestring_gen4_view;
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen4_name_ref_idx ON osm_transportation_name_linestring_gen4((coalesce(name, ref)));
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen4_geometry_idx ON osm_transportation_name_linestring_gen4 USING gist (geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS transportation_name;

-- Trigger to update "osm_transportation_name_network" from "osm_route_member" and "osm_highway_linestring"

CREATE TABLE IF NOT EXISTS transportation_name.network_changes
(
    osm_id bigint,
    UNIQUE (osm_id)
);

CREATE OR REPLACE FUNCTION transportation_name.route_member_store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_name.network_changes(osm_id)
    VALUES (CASE WHEN tg_op IN ('DELETE', 'UPDATE') THEN old.member ELSE new.member END)
    ON CONFLICT(osm_id) DO NOTHING;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_name.highway_linestring_store() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_name.network_changes(osm_id)
    VALUES (CASE WHEN tg_op IN ('DELETE', 'UPDATE') THEN old.osm_id ELSE new.osm_id END)
    ON CONFLICT(osm_id) DO NOTHING;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS transportation_name.updates_network
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION transportation_name.flag_network() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_name.updates_network(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_name.refresh_network() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh transportation_name_network';
    PERFORM update_osm_route_member();

    -- REFRESH osm_transportation_name_network
    DELETE
    FROM osm_transportation_name_network AS n
        USING
            transportation_name.network_changes AS c
    WHERE n.osm_id = c.osm_id;

    UPDATE osm_highway_linestring hl
    SET network = rm.network_type
    FROM transportation_name.network_changes c,
         osm_route_member rm
    WHERE hl.osm_id=c.osm_id
      AND hl.osm_id=rm.member
      AND rm.concurrency_index=1;

    UPDATE osm_highway_linestring_gen_z11 hl
    SET network = rm.network_type
    FROM transportation_name.network_changes c,
         osm_route_member rm
    WHERE hl.osm_id=c.osm_id
      AND hl.osm_id=rm.member
      AND rm.concurrency_index=1;

    INSERT INTO osm_transportation_name_network
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
        level,
        layer,
        indoor,
        network_type,
        route_1, route_2, route_3, route_4, route_5, route_6,
        z_order
    FROM (
        SELECT hl.geometry,
            hl.osm_id,
            CASE WHEN length(hl.name) > 15 THEN osml10n_street_abbrev_all(hl.name) ELSE NULLIF(hl.name, '') END AS name,
            CASE WHEN length(hl.name_en) > 15 THEN osml10n_street_abbrev_en(hl.name_en) ELSE NULLIF(hl.name_en, '') END AS name_en,
            CASE WHEN length(hl.name_de) > 15 THEN osml10n_street_abbrev_de(hl.name_de) ELSE NULLIF(hl.name_de, '') END AS name_de,
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
            CASE WHEN highway IN ('footway', 'steps') THEN layer END AS layer,
            CASE WHEN highway IN ('footway', 'steps') THEN level END AS level,
            CASE WHEN highway IN ('footway', 'steps') THEN indoor END AS indoor,
	    NULLIF(rm1.network, '') || '=' || COALESCE(rm1.ref, '') AS route_1,
	    NULLIF(rm2.network, '') || '=' || COALESCE(rm2.ref, '') AS route_2,
	    NULLIF(rm3.network, '') || '=' || COALESCE(rm3.ref, '') AS route_3,
	    NULLIF(rm4.network, '') || '=' || COALESCE(rm4.ref, '') AS route_4,
	    NULLIF(rm5.network, '') || '=' || COALESCE(rm5.ref, '') AS route_5,
	    NULLIF(rm6.network, '') || '=' || COALESCE(rm6.ref, '') AS route_6,
            hl.z_order
        FROM osm_highway_linestring hl
                JOIN transportation_name.network_changes AS c ON
            hl.osm_id = c.osm_id
		LEFT OUTER JOIN osm_route_member rm1 ON rm1.member = hl.osm_id AND rm1.concurrency_index=1
		LEFT OUTER JOIN osm_route_member rm2 ON rm2.member = hl.osm_id AND rm2.concurrency_index=2
		LEFT OUTER JOIN osm_route_member rm3 ON rm3.member = hl.osm_id AND rm3.concurrency_index=3
		LEFT OUTER JOIN osm_route_member rm4 ON rm4.member = hl.osm_id AND rm4.concurrency_index=4
		LEFT OUTER JOIN osm_route_member rm5 ON rm5.member = hl.osm_id AND rm5.concurrency_index=5
		LEFT OUTER JOIN osm_route_member rm6 ON rm6.member = hl.osm_id AND rm6.concurrency_index=6
	WHERE (hl.name <> '' OR hl.ref <> '' OR rm1.ref <> '' OR rm1.network <> '')
          AND hl.highway <> ''
    ) AS t;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.network_changes;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.updates_network;

    RAISE LOG 'Refresh transportation_name network done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trigger_store_transportation_route_member
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_route_member
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.route_member_store();

CREATE TRIGGER trigger_store_transportation_highway_linestring
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_highway_linestring
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.highway_linestring_store();

CREATE TRIGGER trigger_flag_transportation_name
    AFTER INSERT
    ON transportation_name.network_changes
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation_name.flag_network();

CREATE CONSTRAINT TRIGGER trigger_refresh_network
    AFTER INSERT
    ON transportation_name.updates_network
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.refresh_network();

-- Trigger to update "osm_transportation_name_linestring" from "osm_transportation_name_network"

CREATE TABLE IF NOT EXISTS transportation_name.name_changes
(
    id serial PRIMARY KEY,
    is_old boolean,
    osm_id bigint,
    name character varying,
    name_en character varying,
    name_de character varying,
    tags hstore,
    ref character varying,
    highway character varying,
    subclass character varying,
    brunnel character varying,
    level integer,
    layer integer,
    indoor boolean,
    network_type route_network_type,
    route_1 character varying,
    route_2 character varying,
    route_3 character varying,
    route_4 character varying,
    route_5 character varying,
    route_6 character varying
);

CREATE OR REPLACE FUNCTION transportation_name.name_network_store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op IN ('DELETE', 'UPDATE'))
    THEN
        INSERT INTO transportation_name.name_changes(is_old, osm_id, name, name_en, name_de, tags, ref, highway, subclass,
                                                     brunnel, level, layer, indoor, network_type,
                                                     route_1, route_2, route_3, route_4, route_5, route_6)
        VALUES (TRUE, old.osm_id, old.name, old.name_en, old.name_de, old.tags, old.ref, old.highway, old.subclass,
                old.brunnel, old.level, old.layer, old.indoor, old.network_type,
                old.route_1, old.route_2, old.route_3, old.route_4, old.route_5, old.route_6);
    END IF;
    IF (tg_op IN ('UPDATE', 'INSERT'))
    THEN
        INSERT INTO transportation_name.name_changes(is_old, osm_id, name, name_en, name_de, tags, ref, highway, subclass,
                                                     brunnel, level, layer, indoor, network_type,
                                                     route_1, route_2, route_3, route_4, route_5, route_6)
        VALUES (FALSE, new.osm_id, new.name, new.name_en, new.name_de, new.tags, new.ref, new.highway, new.subclass,
                new.brunnel, new.level, new.layer, new.indoor, new.network_type,
                new.route_1, new.route_2, new.route_3, new.route_4, new.route_5, new.route_6);
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
    SELECT DISTINCT ON (name, name_en, name_de, tags, ref, highway, subclass, brunnel, level, layer, indoor, network_type,
                        route_1, route_2, route_3, route_4, route_5, route_6)
        name,
        name_en,
        name_de,
        tags,
        ref,
        highway,
        subclass,
        brunnel,
        level,
        layer,
        indoor,
        network_type,
        route_1, route_2, route_3, route_4, route_5, route_6,
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
      AND n.tags IS NOT DISTINCT FROM c.tags
      AND n.highway IS NOT DISTINCT FROM c.highway
      AND n.subclass IS NOT DISTINCT FROM c.subclass
      AND n.brunnel IS NOT DISTINCT FROM c.brunnel
      AND n.level IS NOT DISTINCT FROM c.level
      AND n.layer IS NOT DISTINCT FROM c.layer
      AND n.indoor IS NOT DISTINCT FROM c.indoor
      AND n.network IS NOT DISTINCT FROM c.network_type
      AND n.route_1 IS NOT DISTINCT FROM c.route_1
      AND n.route_2 IS NOT DISTINCT FROM c.route_2
      AND n.route_3 IS NOT DISTINCT FROM c.route_3
      AND n.route_4 IS NOT DISTINCT FROM c.route_4
      AND n.route_5 IS NOT DISTINCT FROM c.route_5
      AND n.route_6 IS NOT DISTINCT FROM c.route_6;

    INSERT INTO osm_transportation_name_linestring
    SELECT (ST_Dump(geometry)).geom AS geometry,
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
           route_1, route_2, route_3, route_4, route_5, route_6,
           z_order
    FROM (
        SELECT ST_LineMerge(ST_Collect(n.geometry)) AS geometry,
            n.name,
            n.name_en,
            n.name_de,
            hstore(string_agg(nullif(slice_language_tags(n.tags ||
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
            n.route_1, n.route_2, n.route_3, n.route_4, n.route_5, n.route_6,
            min(n.z_order) AS z_order
        FROM osm_transportation_name_network AS n
            JOIN name_changes_compact AS c ON
                 coalesce(n.name, '') = coalesce(c.name, '')
             AND coalesce(n.ref, '') = coalesce(c.ref, '')
             AND n.name_en IS NOT DISTINCT FROM c.name_en
             AND n.name_de IS NOT DISTINCT FROM c.name_de
             AND n.tags IS NOT DISTINCT FROM c.tags
             AND n.highway IS NOT DISTINCT FROM c.highway
             AND n.subclass IS NOT DISTINCT FROM c.subclass
             AND n.brunnel IS NOT DISTINCT FROM c.brunnel
             AND n.level IS NOT DISTINCT FROM c.level
             AND n.layer IS NOT DISTINCT FROM c.layer
             AND n.indoor IS NOT DISTINCT FROM c.indoor
             AND n.network_type IS NOT DISTINCT FROM c.network_type
             AND n.route_1 IS NOT DISTINCT FROM c.route_1
             AND n.route_2 IS NOT DISTINCT FROM c.route_2
             AND n.route_3 IS NOT DISTINCT FROM c.route_3
             AND n.route_4 IS NOT DISTINCT FROM c.route_4
             AND n.route_5 IS NOT DISTINCT FROM c.route_5
             AND n.route_6 IS NOT DISTINCT FROM c.route_6
        GROUP BY n.name, n.name_en, n.name_de, n.tags, n.ref, n.highway, n.subclass, n.brunnel, n.level, n.layer, n.indoor, n.network_type,
                 n.route_1, n.route_2, n.route_3, n.route_4, n.route_5, n.route_6
    ) AS highway_union;

    -- REFRESH osm_transportation_name_linestring_gen1
    DELETE FROM osm_transportation_name_linestring_gen1 AS n
    USING name_changes_compact AS c
    WHERE
        coalesce(n.name, n.ref) = c.name_ref
        AND n.name IS NOT DISTINCT FROM c.name
        AND n.name_en IS NOT DISTINCT FROM c.name_en
        AND n.name_de IS NOT DISTINCT FROM c.name_de
        AND n.tags IS NOT DISTINCT FROM c.tags
        AND n.ref IS NOT DISTINCT FROM c.ref
        AND n.highway IS NOT DISTINCT FROM c.highway
        AND n.subclass IS NOT DISTINCT FROM c.subclass
        AND n.brunnel IS NOT DISTINCT FROM c.brunnel
        AND n.network IS NOT DISTINCT FROM c.network_type
        AND n.route_1 IS NOT DISTINCT FROM c.route_1
        AND n.route_2 IS NOT DISTINCT FROM c.route_2
        AND n.route_3 IS NOT DISTINCT FROM c.route_3
        AND n.route_4 IS NOT DISTINCT FROM c.route_4
        AND n.route_5 IS NOT DISTINCT FROM c.route_5
        AND n.route_6 IS NOT DISTINCT FROM c.route_6;

    INSERT INTO osm_transportation_name_linestring_gen1
    SELECT n.*
    FROM osm_transportation_name_linestring_gen1_view AS n
        JOIN name_changes_compact AS c ON
            coalesce(n.name, n.ref) = c.name_ref
            AND n.name IS NOT DISTINCT FROM c.name
            AND n.name_en IS NOT DISTINCT FROM c.name_en
            AND n.name_de IS NOT DISTINCT FROM c.name_de
            AND n.tags IS NOT DISTINCT FROM c.tags
            AND n.ref IS NOT DISTINCT FROM c.ref
            AND n.highway IS NOT DISTINCT FROM c.highway
            AND n.subclass IS NOT DISTINCT FROM c.subclass
            AND n.brunnel IS NOT DISTINCT FROM c.brunnel
            AND n.network IS NOT DISTINCT FROM c.network_type
            AND n.route_1 IS NOT DISTINCT FROM c.route_1
            AND n.route_2 IS NOT DISTINCT FROM c.route_2
            AND n.route_3 IS NOT DISTINCT FROM c.route_3
            AND n.route_4 IS NOT DISTINCT FROM c.route_4
            AND n.route_5 IS NOT DISTINCT FROM c.route_5
            AND n.route_6 IS NOT DISTINCT FROM c.route_6;

    -- REFRESH osm_transportation_name_linestring_gen2
    DELETE FROM osm_transportation_name_linestring_gen2 AS n
    USING name_changes_compact AS c
    WHERE
        coalesce(n.name, n.ref) = c.name_ref
        AND n.name IS NOT DISTINCT FROM c.name
        AND n.name_en IS NOT DISTINCT FROM c.name_en
        AND n.name_de IS NOT DISTINCT FROM c.name_de
        AND n.tags IS NOT DISTINCT FROM c.tags
        AND n.ref IS NOT DISTINCT FROM c.ref
        AND n.highway IS NOT DISTINCT FROM c.highway
        AND n.subclass IS NOT DISTINCT FROM c.subclass
        AND n.brunnel IS NOT DISTINCT FROM c.brunnel
        AND n.network IS NOT DISTINCT FROM c.network_type
        AND n.route_1 IS NOT DISTINCT FROM c.route_1
        AND n.route_2 IS NOT DISTINCT FROM c.route_2
        AND n.route_3 IS NOT DISTINCT FROM c.route_3
        AND n.route_4 IS NOT DISTINCT FROM c.route_4
        AND n.route_5 IS NOT DISTINCT FROM c.route_5
        AND n.route_6 IS NOT DISTINCT FROM c.route_6;

    INSERT INTO osm_transportation_name_linestring_gen2
    SELECT n.*
    FROM osm_transportation_name_linestring_gen2_view AS n
        JOIN name_changes_compact AS c ON
            coalesce(n.name, n.ref) = c.name_ref
            AND n.name IS NOT DISTINCT FROM c.name
            AND n.name_en IS NOT DISTINCT FROM c.name_en
            AND n.name_de IS NOT DISTINCT FROM c.name_de
            AND n.tags IS NOT DISTINCT FROM c.tags
            AND n.ref IS NOT DISTINCT FROM c.ref
            AND n.highway IS NOT DISTINCT FROM c.highway
            AND n.subclass IS NOT DISTINCT FROM c.subclass
            AND n.brunnel IS NOT DISTINCT FROM c.brunnel
            AND n.network IS NOT DISTINCT FROM c.network_type
            AND n.route_1 IS NOT DISTINCT FROM c.route_1
            AND n.route_2 IS NOT DISTINCT FROM c.route_2
            AND n.route_3 IS NOT DISTINCT FROM c.route_3
            AND n.route_4 IS NOT DISTINCT FROM c.route_4
            AND n.route_5 IS NOT DISTINCT FROM c.route_5
            AND n.route_6 IS NOT DISTINCT FROM c.route_6;

    -- REFRESH osm_transportation_name_linestring_gen3
    DELETE FROM osm_transportation_name_linestring_gen3 AS n
    USING name_changes_compact AS c
    WHERE
        coalesce(n.name, n.ref) = c.name_ref
        AND n.name IS NOT DISTINCT FROM c.name
        AND n.name_en IS NOT DISTINCT FROM c.name_en
        AND n.name_de IS NOT DISTINCT FROM c.name_de
        AND n.tags IS NOT DISTINCT FROM c.tags
        AND n.ref IS NOT DISTINCT FROM c.ref
        AND n.highway IS NOT DISTINCT FROM c.highway
        AND n.subclass IS NOT DISTINCT FROM c.subclass
        AND n.brunnel IS NOT DISTINCT FROM c.brunnel
        AND n.network IS NOT DISTINCT FROM c.network_type
        AND n.route_1 IS NOT DISTINCT FROM c.route_1
        AND n.route_2 IS NOT DISTINCT FROM c.route_2
        AND n.route_3 IS NOT DISTINCT FROM c.route_3
        AND n.route_4 IS NOT DISTINCT FROM c.route_4
        AND n.route_5 IS NOT DISTINCT FROM c.route_5
        AND n.route_6 IS NOT DISTINCT FROM c.route_6;

    INSERT INTO osm_transportation_name_linestring_gen3
    SELECT n.*
    FROM osm_transportation_name_linestring_gen3_view AS n
        JOIN name_changes_compact AS c ON
            coalesce(n.name, n.ref) = c.name_ref
            AND n.name IS NOT DISTINCT FROM c.name
            AND n.name_en IS NOT DISTINCT FROM c.name_en
            AND n.name_de IS NOT DISTINCT FROM c.name_de
            AND n.tags IS NOT DISTINCT FROM c.tags
            AND n.ref IS NOT DISTINCT FROM c.ref
            AND n.highway IS NOT DISTINCT FROM c.highway
            AND n.subclass IS NOT DISTINCT FROM c.subclass
            AND n.brunnel IS NOT DISTINCT FROM c.brunnel
            AND n.network IS NOT DISTINCT FROM c.network_type
            AND n.route_1 IS NOT DISTINCT FROM c.route_1
            AND n.route_2 IS NOT DISTINCT FROM c.route_2
            AND n.route_3 IS NOT DISTINCT FROM c.route_3
            AND n.route_4 IS NOT DISTINCT FROM c.route_4
            AND n.route_5 IS NOT DISTINCT FROM c.route_5
            AND n.route_6 IS NOT DISTINCT FROM c.route_6;

    -- REFRESH osm_transportation_name_linestring_gen4
    DELETE FROM osm_transportation_name_linestring_gen4 AS n
    USING name_changes_compact AS c
    WHERE
        coalesce(n.name, n.ref) = c.name_ref
        AND n.name IS NOT DISTINCT FROM c.name
        AND n.name_en IS NOT DISTINCT FROM c.name_en
        AND n.name_de IS NOT DISTINCT FROM c.name_de
        AND n.tags IS NOT DISTINCT FROM c.tags
        AND n.ref IS NOT DISTINCT FROM c.ref
        AND n.highway IS NOT DISTINCT FROM c.highway
        AND n.subclass IS NOT DISTINCT FROM c.subclass
        AND n.brunnel IS NOT DISTINCT FROM c.brunnel
        AND n.network IS NOT DISTINCT FROM c.network_type
        AND n.route_1 IS NOT DISTINCT FROM c.route_1
        AND n.route_2 IS NOT DISTINCT FROM c.route_2
        AND n.route_3 IS NOT DISTINCT FROM c.route_3
        AND n.route_4 IS NOT DISTINCT FROM c.route_4
        AND n.route_5 IS NOT DISTINCT FROM c.route_5
        AND n.route_6 IS NOT DISTINCT FROM c.route_6;

    INSERT INTO osm_transportation_name_linestring_gen4
    SELECT n.*
    FROM osm_transportation_name_linestring_gen4_view AS n
        JOIN name_changes_compact AS c ON
            coalesce(n.name, n.ref) = c.name_ref
            AND n.name IS NOT DISTINCT FROM c.name
            AND n.name_en IS NOT DISTINCT FROM c.name_en
            AND n.name_de IS NOT DISTINCT FROM c.name_de
            AND n.tags IS NOT DISTINCT FROM c.tags
            AND n.ref IS NOT DISTINCT FROM c.ref
            AND n.highway IS NOT DISTINCT FROM c.highway
            AND n.subclass IS NOT DISTINCT FROM c.subclass
            AND n.brunnel IS NOT DISTINCT FROM c.brunnel
            AND n.network IS NOT DISTINCT FROM c.network_type
            AND n.route_1 IS NOT DISTINCT FROM c.route_1
            AND n.route_2 IS NOT DISTINCT FROM c.route_2
            AND n.route_3 IS NOT DISTINCT FROM c.route_3
            AND n.route_4 IS NOT DISTINCT FROM c.route_4
            AND n.route_5 IS NOT DISTINCT FROM c.route_5
            AND n.route_6 IS NOT DISTINCT FROM c.route_6;

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
