DROP TRIGGER IF EXISTS trigger_flag ON osm_waterway_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON waterway.updates;

-- We merge the waterways by name like the highways
-- This helps to drop not important rivers (since they do not have a name)
-- and also makes it possible to filter out too short rivers

-- etldoc: osm_waterway_linestring ->  osm_important_waterway_linestring
DROP MATERIALIZED VIEW IF EXISTS osm_important_waterway_linestring CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_important_waterway_linestring_gen1 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_important_waterway_linestring_gen2 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_important_waterway_linestring_gen3 CASCADE;

CREATE INDEX IF NOT EXISTS osm_waterway_linestring_waterway_partial_idx
    ON osm_waterway_linestring(waterway)
    WHERE waterway = 'river';

CREATE INDEX IF NOT EXISTS osm_waterway_linestring_name_partial_idx
    ON osm_waterway_linestring(name)
    WHERE name <> '';

CREATE MATERIALIZED VIEW osm_important_waterway_linestring AS (
    SELECT
        (ST_Dump(geometry)).geom AS geometry,
        name, name_en, name_de, tags
    FROM (
        SELECT
            ST_LineMerge(ST_Union(geometry)) AS geometry,
            name, name_en, name_de, tags
        FROM osm_waterway_linestring
        WHERE name <> '' AND waterway = 'river'
        GROUP BY name, name_en, name_de, tags
    ) AS waterway_union
);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_geometry_idx ON osm_important_waterway_linestring USING gist(geometry);

-- etldoc: osm_important_waterway_linestring -> osm_important_waterway_linestring_gen1
CREATE MATERIALIZED VIEW osm_important_waterway_linestring_gen1 AS (
    SELECT ST_Simplify(geometry, 60) AS geometry, name, name_en, name_de, tags
    FROM osm_important_waterway_linestring
    WHERE ST_Length(geometry) > 1000
);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen1_geometry_idx ON osm_important_waterway_linestring_gen1 USING gist(geometry);

-- etldoc: osm_important_waterway_linestring_gen1 -> osm_important_waterway_linestring_gen2
CREATE MATERIALIZED VIEW osm_important_waterway_linestring_gen2 AS (
    SELECT ST_Simplify(geometry, 100) AS geometry, name, name_en, name_de, tags
    FROM osm_important_waterway_linestring_gen1
    WHERE ST_Length(geometry) > 4000
);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen2_geometry_idx ON osm_important_waterway_linestring_gen2 USING gist(geometry);

-- etldoc: osm_important_waterway_linestring_gen2 -> osm_important_waterway_linestring_gen3
CREATE MATERIALIZED VIEW osm_important_waterway_linestring_gen3 AS (
    SELECT ST_Simplify(geometry, 200) AS geometry, name, name_en, name_de, tags
    FROM osm_important_waterway_linestring_gen2
    WHERE ST_Length(geometry) > 8000
);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen3_geometry_idx ON osm_important_waterway_linestring_gen3 USING gist(geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS waterway;

CREATE TABLE IF NOT EXISTS waterway.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION waterway.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO waterway.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION waterway.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh waterway';
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring;
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring_gen1;
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring_gen2;
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring_gen3;
    DELETE FROM waterway.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_waterway_linestring
    FOR EACH STATEMENT
    EXECUTE PROCEDURE waterway.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON waterway.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE waterway.refresh();
