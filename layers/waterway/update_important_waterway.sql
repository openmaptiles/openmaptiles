DROP TRIGGER IF EXISTS trigger_store ON osm_waterway_linestring;
DROP TRIGGER IF EXISTS trigger_flag ON osm_waterway_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON waterway_important.updates;

-- We merge the waterways by name like the highways
-- This helps to drop not important rivers (since they do not have a name)
-- and also makes it possible to filter out too short rivers

CREATE INDEX IF NOT EXISTS osm_waterway_linestring_waterway_partial_idx
    ON osm_waterway_linestring (waterway)
    WHERE waterway = 'river';

CREATE INDEX IF NOT EXISTS osm_waterway_linestring_name_partial_idx
    ON osm_waterway_linestring (name)
    WHERE name <> '';

-- etldoc: osm_waterway_linestring ->  osm_important_waterway_linestring
CREATE TABLE IF NOT EXISTS osm_important_waterway_linestring AS
SELECT (ST_Dump(geometry)).geom AS geometry,
       name,
       name_en,
       name_de,
       tags
FROM (
         SELECT ST_LineMerge(ST_Union(geometry)) AS geometry,
                name,
                name_en,
                name_de,
                slice_language_tags(tags) AS tags
         FROM osm_waterway_linestring
         WHERE name <> ''
           AND waterway = 'river'
           AND ST_IsValid(geometry)
         GROUP BY name, name_en, name_de, slice_language_tags(tags)
     ) AS waterway_union;
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_names ON osm_important_waterway_linestring (name);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_geometry_idx ON osm_important_waterway_linestring USING gist (geometry);

-- etldoc: osm_important_waterway_linestring -> osm_important_waterway_linestring_gen1
CREATE OR REPLACE VIEW osm_important_waterway_linestring_gen1_view AS
SELECT ST_Simplify(geometry, 60) AS geometry, name, name_en, name_de, tags
FROM osm_important_waterway_linestring
WHERE ST_Length(geometry) > 1000;

CREATE TABLE IF NOT EXISTS osm_important_waterway_linestring_gen1 AS
SELECT *
FROM osm_important_waterway_linestring_gen1_view;
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen1_name_idx ON osm_important_waterway_linestring_gen1 (name);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen1_geometry_idx ON osm_important_waterway_linestring_gen1 USING gist (geometry);

-- etldoc: osm_important_waterway_linestring_gen1 -> osm_important_waterway_linestring_gen2
CREATE OR REPLACE VIEW osm_important_waterway_linestring_gen2_view AS
SELECT ST_Simplify(geometry, 100) AS geometry, name, name_en, name_de, tags
FROM osm_important_waterway_linestring_gen1
WHERE ST_Length(geometry) > 4000;

CREATE TABLE IF NOT EXISTS osm_important_waterway_linestring_gen2 AS
SELECT *
FROM osm_important_waterway_linestring_gen2_view;
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen2_name_idx ON osm_important_waterway_linestring_gen2 (name);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen2_geometry_idx ON osm_important_waterway_linestring_gen2 USING gist (geometry);

-- etldoc: osm_important_waterway_linestring_gen2 -> osm_important_waterway_linestring_gen3
CREATE OR REPLACE VIEW osm_important_waterway_linestring_gen3_view AS
SELECT ST_Simplify(geometry, 200) AS geometry, name, name_en, name_de, tags
FROM osm_important_waterway_linestring_gen2
WHERE ST_Length(geometry) > 8000;

CREATE TABLE IF NOT EXISTS osm_important_waterway_linestring_gen3 AS
SELECT *
FROM osm_important_waterway_linestring_gen3_view;
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen3_name_idx ON osm_important_waterway_linestring_gen3 (name);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen3_geometry_idx ON osm_important_waterway_linestring_gen3 USING gist (geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS waterway_important;

CREATE TABLE IF NOT EXISTS waterway_important.changes
(
    id serial PRIMARY KEY,
    osm_id bigint,
    is_old boolean,
    name character varying,
    name_en character varying,
    name_de character varying,
    tags hstore
);
CREATE OR REPLACE FUNCTION waterway_important.store() RETURNS trigger AS
$$
BEGIN
    IF (tg_op IN ('DELETE', 'UPDATE')) AND OLD.name <> '' AND OLD.waterway = 'river' THEN
        INSERT INTO waterway_important.changes(is_old, name, name_en, name_de, tags)
        VALUES (TRUE, OLD.name, OLD.name_en, OLD.name_de, slice_language_tags(OLD.tags));
    END IF;
    IF (tg_op IN ('UPDATE', 'INSERT')) AND NEW.name <> '' AND NEW.waterway = 'river' THEN
        INSERT INTO waterway_important.changes(is_old, name, name_en, name_de, tags)
        VALUES (FALSE, NEW.name, NEW.name_en, NEW.name_de, slice_language_tags(NEW.tags));
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS waterway_important.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION waterway_important.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO waterway_important.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION waterway_important.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh waterway';

    -- REFRESH osm_important_waterway_linestring

    -- Compact the change history to keep only the first and last version, and then uniq version of row
    CREATE TEMP TABLE changes_compact AS
    SELECT DISTINCT ON (name, name_en, name_de, tags)
        name,
        name_en,
        name_de,
        tags
    FROM ((
              SELECT DISTINCT ON (osm_id) *
              FROM waterway_important.changes
              WHERE is_old
              ORDER BY osm_id,
                       id ASC
          )
          UNION ALL
          (
              SELECT DISTINCT ON (osm_id) *
              FROM waterway_important.changes
              WHERE NOT is_old
              ORDER BY osm_id,
                       id DESC
          )) AS t;

    DELETE
    FROM osm_important_waterway_linestring AS w
        USING changes_compact AS c
    WHERE w.name = c.name
      AND w.name_en IS NOT DISTINCT FROM c.name_en
      AND w.name_de IS NOT DISTINCT FROM c.name_de
      AND w.tags IS NOT DISTINCT FROM c.tags;

    INSERT INTO osm_important_waterway_linestring
    SELECT (ST_Dump(geometry)).geom AS geometry,
           name,
           name_en,
           name_de,
           tags
    FROM (
             SELECT ST_LineMerge(ST_Union(geometry)) AS geometry,
                    w.name,
                    w.name_en,
                    w.name_de,
                    slice_language_tags(w.tags) AS tags
             FROM osm_waterway_linestring AS w
                      JOIN changes_compact AS c ON
                     w.name = c.name AND w.name_en IS NOT DISTINCT FROM c.name_en AND
                     w.name_de IS NOT DISTINCT FROM c.name_de AND
                     slice_language_tags(w.tags) IS NOT DISTINCT FROM c.tags
             WHERE w.name <> ''
               AND w.waterway = 'river'
               AND ST_IsValid(geometry)
             GROUP BY w.name, w.name_en, w.name_de, slice_language_tags(w.tags)
         ) AS waterway_union;

    -- REFRESH sm_important_waterway_linestring_gen1
    DELETE
    FROM osm_important_waterway_linestring_gen1 AS w
        USING changes_compact AS c
    WHERE w.name = c.name
      AND w.name_en IS NOT DISTINCT FROM c.name_en
      AND w.name_de IS NOT DISTINCT FROM c.name_de
      AND w.tags IS NOT DISTINCT FROM c.tags;

    INSERT INTO osm_important_waterway_linestring_gen1
    SELECT w.*
    FROM osm_important_waterway_linestring_gen1_view AS w
             NATURAL JOIN changes_compact AS c;

    -- REFRESH osm_important_waterway_linestring_gen2
    DELETE
    FROM osm_important_waterway_linestring_gen2 AS w
        USING changes_compact AS c
    WHERE w.name = c.name
      AND w.name_en IS NOT DISTINCT FROM c.name_en
      AND w.name_de IS NOT DISTINCT FROM c.name_de
      AND w.tags IS NOT DISTINCT FROM c.tags;

    INSERT INTO osm_important_waterway_linestring_gen2
    SELECT w.*
    FROM osm_important_waterway_linestring_gen2_view AS w
             NATURAL JOIN changes_compact AS c;

    -- REFRESH osm_important_waterway_linestring_gen3
    DELETE
    FROM osm_important_waterway_linestring_gen3 AS w
        USING changes_compact AS c
    WHERE w.name = c.name
      AND w.name_en IS NOT DISTINCT FROM c.name_en
      AND w.name_de IS NOT DISTINCT FROM c.name_de
      AND w.tags IS NOT DISTINCT FROM c.tags;

    INSERT INTO osm_important_waterway_linestring_gen3
    SELECT w.*
    FROM osm_important_waterway_linestring_gen3_view AS w
             NATURAL JOIN changes_compact AS c;

    DROP TABLE changes_compact;
    -- noinspection SqlWithoutWhere
    DELETE FROM waterway_important.changes;
    -- noinspection SqlWithoutWhere
    DELETE FROM waterway_important.updates;

    RAISE LOG 'Refresh waterway done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_waterway_linestring
    FOR EACH ROW
EXECUTE PROCEDURE waterway_important.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_waterway_linestring
    FOR EACH STATEMENT
EXECUTE PROCEDURE waterway_important.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON waterway_important.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE waterway_important.refresh();
