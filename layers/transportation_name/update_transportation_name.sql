DROP TRIGGER IF EXISTS trigger_flag_transportation_name ON osm_highway_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON transportation_name.updates;

-- Instead of using relations to find out the road names we
-- stitch together the touching ways with the same name
-- to allow for nice label rendering
-- Because this works well for roads that do not have relations as well


-- etldoc: osm_highway_linestring ->  osm_transportation_name_network
-- etldoc: osm_route_member ->  osm_transportation_name_network
CREATE MATERIALIZED VIEW osm_transportation_name_network AS
(
SELECT hl.geometry,
       hl.osm_id,
       CASE WHEN length(hl.name) > 15 THEN osml10n_street_abbrev_all(hl.name) ELSE hl.name END AS "name",
       CASE WHEN length(hl.name_en) > 15 THEN osml10n_street_abbrev_en(hl.name_en) ELSE hl.name_en END AS "name_en",
       CASE WHEN length(hl.name_de) > 15 THEN osml10n_street_abbrev_de(hl.name_de) ELSE hl.name_de END AS "name_de",
       hl.tags,
       rm.network_type,
       CASE
           WHEN (rm.network_type IS NOT NULL AND nullif(rm.ref::text, '') IS NOT NULL)
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
         LEFT JOIN osm_route_member rm ON (rm.member = hl.osm_id)
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
CREATE INDEX IF NOT EXISTS osm_transportation_name_network_geometry_idx ON osm_transportation_name_network USING gist (geometry);


-- etldoc: osm_transportation_name_network ->  osm_transportation_name_linestring
CREATE MATERIALIZED VIEW osm_transportation_name_linestring AS
(
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
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
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

CREATE TABLE IF NOT EXISTS transportation_name.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION transportation_name.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO transportation_name.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION transportation_name.refresh() RETURNS trigger AS
$$
BEGIN
    RAISE LOG 'Refresh transportation_name';
    PERFORM update_osm_route_member();
    REFRESH MATERIALIZED VIEW osm_transportation_name_network;
    REFRESH MATERIALIZED VIEW osm_transportation_name_linestring;
    REFRESH MATERIALIZED VIEW osm_transportation_name_linestring_gen1;
    REFRESH MATERIALIZED VIEW osm_transportation_name_linestring_gen2;
    REFRESH MATERIALIZED VIEW osm_transportation_name_linestring_gen3;
    REFRESH MATERIALIZED VIEW osm_transportation_name_linestring_gen4;
    -- noinspection SqlWithoutWhere
    DELETE FROM transportation_name.updates;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag_transportation_name
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_route_member
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation_name.flag();

CREATE TRIGGER trigger_flag_transportation_name
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_highway_linestring
    FOR EACH STATEMENT
EXECUTE PROCEDURE transportation_name.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON transportation_name.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE transportation_name.refresh();
