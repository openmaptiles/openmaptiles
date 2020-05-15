-- Instead of using relations to find out the road names we
-- stitch together the touching ways with the same name
-- to allow for nice label rendering
-- Because this works well for roads that do not have relations as well


-- etldoc: osm_highway_linestring ->  osm_transportation_name_network
-- etldoc: osm_route_member ->  osm_transportation_name_network
CREATE TABLE IF NOT EXISTS osm_transportation_name_network AS
SELECT hl.geometry,
       hl.osm_id,
       CASE WHEN length(hl.name) > 15 THEN osml10n_street_abbrev_all(hl.name) ELSE hl.name END AS "name",
       CASE WHEN length(hl.name_en) > 15 THEN osml10n_street_abbrev_en(hl.name_en) ELSE hl.name_en END AS "name_en",
       CASE WHEN length(hl.name_de) > 15 THEN osml10n_street_abbrev_de(hl.name_de) ELSE hl.name_de END AS "name_de",
       hl.tags,
       rm.network_type,
       CASE
           WHEN rm.network_type IS NOT NULL AND nullif(rm.ref::text, '') IS NOT NULL
               THEN rm.ref::text
           ELSE hl.ref
           END AS ref,
       hl.highway,
       hl.construction,
       CASE WHEN highway IN ('footway', 'steps') THEN layer END AS layer,
       CASE WHEN highway IN ('footway', 'steps') THEN "level" END AS "level",
       CASE WHEN highway IN ('footway', 'steps') THEN indoor END AS indoor,
       ROW_NUMBER() OVER (PARTITION BY hl.osm_id
           ORDER BY rm.network_type) AS "rank",
       hl.z_order
FROM osm_highway_linestring hl
         LEFT JOIN osm_route_member rm ON
    rm.member = hl.osm_id
;
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_osm_id_idx ON osm_transportation_name_network (osm_id);
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_geometry_idx ON osm_transportation_name_network USING gist (geometry);


-- etldoc: osm_transportation_name_network ->  osm_transportation_name_linestring
CREATE TABLE IF NOT EXISTS osm_transportation_name_linestring AS
SELECT (ST_Dump(geometry)).geom AS geometry,
       NULL::bigint AS osm_id,
       name,
       name_en,
       name_de,
       tags || get_basic_names(tags, geometry) AS "tags",
       ref,
       highway,
       construction,
       "level",
       layer,
       indoor,
       network_type AS network,
       z_order
FROM (
         SELECT ST_LineMerge(ST_Collect(geometry)) AS geometry,
                name,
                name_en,
                name_de,
                hstore(string_agg(nullif(slice_language_tags(tags ||
                                                             hstore(ARRAY ['name', name, 'name:en', name_en, 'name:de', name_de]))::text,
                                         ''), ',')) AS "tags",
                ref,
                highway,
                construction,
                "level",
                layer,
                indoor,
                network_type,
                min(z_order) AS z_order
         FROM osm_transportation_name_network
         WHERE ("rank" = 1 OR "rank" IS NULL)
           AND (name <> '' OR ref <> '')
           AND NULLIF(highway, '') IS NOT NULL
         GROUP BY name, name_en, name_de, ref, highway, construction, "level", layer, indoor, network_type
     ) AS highway_union
;
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_name_idx ON osm_transportation_name_linestring (name);
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_geometry_idx ON osm_transportation_name_linestring USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_highway_partial_idx
    ON osm_transportation_name_linestring (highway, construction)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_name_linestring -> osm_transportation_name_linestring_gen1
CREATE MATERIALIZED VIEW osm_transportation_name_linestring_gen1 AS
(
SELECT ST_Simplify(geometry, 50) AS geometry,
       osm_id,
       name,
       name_en,
       name_de,
       tags,
       ref,
       highway,
       construction,
       network,
       z_order
FROM osm_transportation_name_linestring
WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND construction IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 8000
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen1_geometry_idx ON osm_transportation_name_linestring_gen1 USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen1_highway_partial_idx
    ON osm_transportation_name_linestring_gen1 (highway, construction)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_name_linestring_gen1 -> osm_transportation_name_linestring_gen2
CREATE MATERIALIZED VIEW osm_transportation_name_linestring_gen2 AS
(
SELECT ST_Simplify(geometry, 120) AS geometry,
       osm_id,
       name,
       name_en,
       name_de,
       tags,
       ref,
       highway,
       construction,
       network,
       z_order
FROM osm_transportation_name_linestring_gen1
WHERE (highway IN ('motorway', 'trunk') OR highway = 'construction' AND construction IN ('motorway', 'trunk'))
  AND ST_Length(geometry) > 14000
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen2_geometry_idx ON osm_transportation_name_linestring_gen2 USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen2_highway_partial_idx
    ON osm_transportation_name_linestring_gen2 (highway, construction)
    WHERE highway IN ('motorway', 'trunk', 'construction');

-- etldoc: osm_transportation_name_linestring_gen2 -> osm_transportation_name_linestring_gen3
CREATE MATERIALIZED VIEW osm_transportation_name_linestring_gen3 AS
(
SELECT ST_Simplify(geometry, 200) AS geometry,
       osm_id,
       name,
       name_en,
       name_de,
       tags,
       ref,
       highway,
       construction,
       network,
       z_order
FROM osm_transportation_name_linestring_gen2
WHERE (highway = 'motorway' OR highway = 'construction' AND construction = 'motorway')
  AND ST_Length(geometry) > 20000
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen3_geometry_idx ON osm_transportation_name_linestring_gen3 USING gist (geometry);

CREATE INDEX IF NOT EXISTS osm_transportation_name_linestring_gen3_highway_partial_idx
    ON osm_transportation_name_linestring_gen3 (highway, construction)
    WHERE highway IN ('motorway', 'construction');

-- etldoc: osm_transportation_name_linestring_gen3 -> osm_transportation_name_linestring_gen4
CREATE MATERIALIZED VIEW osm_transportation_name_linestring_gen4 AS
(
SELECT ST_Simplify(geometry, 500) AS geometry,
       osm_id,
       name,
       name_en,
       name_de,
       tags,
       ref,
       highway,
       construction,
       network,
       z_order
FROM osm_transportation_name_linestring_gen3
WHERE (highway = 'motorway' OR highway = 'construction' AND construction = 'motorway')
  AND ST_Length(geometry) > 20000
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
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
BEGIN
    RAISE LOG 'Refresh transportation_name_network';
    PERFORM update_osm_route_member();

    -- REFRESH osm_transportation_name_network
    DELETE
    FROM osm_transportation_name_network AS n
        USING
            transportation_name.network_changes AS c
    WHERE n.osm_id = c.osm_id;

    INSERT INTO osm_transportation_name_network
    SELECT hl.geometry,
           hl.osm_id,
           CASE WHEN length(hl.name) > 15 THEN osml10n_street_abbrev_all(hl.name) ELSE hl.name END AS "name",
           CASE WHEN length(hl.name_en) > 15 THEN osml10n_street_abbrev_en(hl.name_en) ELSE hl.name_en END AS "name_en",
           CASE WHEN length(hl.name_de) > 15 THEN osml10n_street_abbrev_de(hl.name_de) ELSE hl.name_de END AS "name_de",
           hl.tags,
           rm.network_type,
           CASE
               WHEN rm.network_type IS NOT NULL AND nullif(rm.ref::text, '') IS NOT NULL
                   THEN rm.ref::text
               ELSE hl.ref
               END AS ref,
           hl.highway,
           hl.construction,
           CASE WHEN highway IN ('footway', 'steps') THEN layer END AS layer,
           CASE WHEN highway IN ('footway', 'steps') THEN "level" END AS "level",
           CASE WHEN highway IN ('footway', 'steps') THEN indoor END AS indoor,
           ROW_NUMBER() OVER (PARTITION BY hl.osm_id ORDER BY rm.network_type) AS "rank",
           hl.z_order
    FROM osm_highway_linestring hl
             JOIN transportation_name.network_changes AS c ON
        hl.osm_id = c.osm_id
             LEFT JOIN osm_route_member rm ON
        rm.member = hl.osm_id;

    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.network_changes;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.updates_network;
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
    name character varying,
    name_en character varying,
    name_de character varying,
    ref character varying,
    highway character varying,
    construction character varying,
    "level" integer,
    layer integer,
    indoor boolean,
    network_type route_network_type,
    UNIQUE (is_old, name, name_en, name_de, ref, highway, construction, "level", layer, indoor, network_type)
);

CREATE OR REPLACE FUNCTION transportation_name.name_network_store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op IN ('DELETE', 'UPDATE')) AND
       (old."rank" = 1 OR old."rank" IS NULL)
        AND (old.name <> '' OR old.ref <> '')
        AND NULLIF(old.highway, '') IS NOT NULL
    THEN
        INSERT INTO transportation_name.name_changes(is_old, name, name_en, name_de, ref, highway, construction,
                                                     "level", layer, indoor, network_type)
        VALUES (TRUE, old.name, old.name_en, old.name_de, old.ref, old.highway, old.construction, old."level",
                old.layer, old.indoor, old.network_type)
        ON CONFLICT(is_old, name, name_en, name_de, ref, highway, construction, "level", layer, indoor, network_type) DO NOTHING;
    END IF;
    IF (tg_op IN ('UPDATE', 'INSERT')) AND
       (new."rank" = 1 OR new."rank" IS NULL)
        AND (new.name <> '' OR new.ref <> '')
        AND NULLIF(new.highway, '') IS NOT NULL
    THEN
        INSERT INTO transportation_name.name_changes(is_old, name, name_en, name_de, ref, highway, construction,
                                                     "level", layer, indoor, network_type)
        VALUES (FALSE, new.name, new.name_en, new.name_de, new.ref, new.highway, new.construction, new."level",
                new.layer, new.indoor, new.network_type)
        ON CONFLICT(is_old, name, name_en, name_de, ref, highway, construction, "level", layer, indoor, network_type) DO NOTHING;
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
BEGIN
    RAISE LOG 'Refresh transportation_name';

    -- REFRESH osm_transportation_name_linestring
    DELETE
    FROM osm_transportation_name_linestring AS n
        USING transportation_name.name_changes AS c
    WHERE c.is_old
      AND n.name IS NOT DISTINCT FROM c.name
      AND n.name_en IS NOT DISTINCT FROM c.name_en
      AND n.name_de IS NOT DISTINCT FROM c.name_de
      AND n.ref IS NOT DISTINCT FROM c.ref
      AND n.highway IS NOT DISTINCT FROM c.highway
      AND n.construction IS NOT DISTINCT FROM c.construction
      AND n."level" IS NOT DISTINCT FROM c."level"
      AND n.layer IS NOT DISTINCT FROM c.layer
      AND n.indoor IS NOT DISTINCT FROM c.indoor
      AND n.network IS NOT DISTINCT FROM c.network_type;

    INSERT INTO osm_transportation_name_linestring
    SELECT (ST_Dump(geometry)).geom AS geometry,
           NULL::bigint AS osm_id,
           name,
           name_en,
           name_de,
           tags || get_basic_names(tags, geometry) AS "tags",
           ref,
           highway,
           construction,
           "level",
           layer,
           indoor,
           network_type AS network,
           z_order
    FROM (
             SELECT ST_LineMerge(ST_Collect(geometry)) AS geometry,
                    n.name,
                    n.name_en,
                    n.name_de,
                    hstore(string_agg(nullif(slice_language_tags(n.tags || hstore(
                            ARRAY ['name', n.name, 'name:en', n.name_en, 'name:de', n.name_de]))::text, ''), ',')) AS "tags",
                    n.ref,
                    n.highway,
                    n.construction,
                    n."level",
                    n.layer,
                    n.indoor,
                    n.network_type,
                    min(n.z_order) AS z_order
             FROM osm_transportation_name_network AS n
                      JOIN transportation_name.name_changes AS c ON
                     NOT c.is_old
                 AND n.name IS NOT DISTINCT FROM c.name AND n.name_en IS NOT DISTINCT FROM c.name_en
                 AND n.name_de IS NOT DISTINCT FROM c.name_de AND n.ref IS NOT DISTINCT FROM c.ref
                 AND n.highway IS NOT DISTINCT FROM c.highway AND n.construction IS NOT DISTINCT FROM c.construction
                 AND n."level" IS NOT DISTINCT FROM c."level" AND n.layer IS NOT DISTINCT FROM c.layer
                 AND n.indoor IS NOT DISTINCT FROM c.indoor AND n.network_type IS NOT DISTINCT FROM c.network_type
             WHERE (n."rank" = 1 OR n."rank" IS NULL)
               AND (n.name <> '' OR n.ref <> '')
               AND NULLIF(n.highway, '') IS NOT NULL
             GROUP BY n.name, n.name_en, n.name_de, n.ref, n.highway, n.construction, n."level", n.layer, n.indoor,
                      n.network_type
         ) AS highway_union;

    REFRESH MATERIALIZED VIEW osm_transportation_name_linestring_gen1;
    REFRESH MATERIALIZED VIEW osm_transportation_name_linestring_gen2;
    REFRESH MATERIALIZED VIEW osm_transportation_name_linestring_gen3;
    REFRESH MATERIALIZED VIEW osm_transportation_name_linestring_gen4;
    DELETE FROM transportation_name.name_changes;
    DELETE FROM transportation_name.updates_name;
    RETURN NULL;
END;
$BODY$
    LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trigger_store_transportation_name_network ON osm_transportation_name_network;
CREATE TRIGGER trigger_store_transportation_name_network
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_transportation_name_network
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.name_network_store();

DROP TRIGGER IF EXISTS trigger_flag_name ON transportation_name.name_changes;
CREATE TRIGGER trigger_flag_name
    AFTER INSERT
    ON transportation_name.name_changes
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation_name.flag_name();

DROP TRIGGER IF EXISTS trigger_refresh_name ON transportation_name.updates_name;
CREATE CONSTRAINT TRIGGER trigger_refresh_name
    AFTER INSERT
    ON transportation_name.updates_name
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.refresh_name();
