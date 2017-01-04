
-- We merge the waterways by name like the highways
-- This helps to drop not important rivers (since they do not have a name)
-- and also makes it possible to filter out too short rivers

-- etldoc: osm_waterway_linestring ->  osm_important_waterway_linestring
CREATE MATERIALIZED VIEW osm_important_waterway_linestring AS (
    SELECT
        (ST_Dump(geometry)).geom AS geometry,
        name
    FROM (
        SELECT
            ST_LineMerge(ST_Union(geometry)) AS geometry,
            name
        FROM osm_waterway_linestring
        WHERE name <> '' AND waterway = 'river'
        GROUP BY name
    ) AS waterway_union
) WITH NO DATA;
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_geometry_idx ON osm_important_waterway_linestring USING gist(geometry);

-- etldoc: osm_important_waterway_linestring -> osm_important_waterway_linestring_gen1
CREATE MATERIALIZED VIEW osm_important_waterway_linestring_gen1 AS (
    SELECT ST_Simplify(geometry, 60) AS geometry, name
    FROM osm_important_waterway_linestring
    WHERE ST_Length(geometry) > 1000
) WITH NO DATA;
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen1_geometry_idx ON osm_important_waterway_linestring_gen1 USING gist(geometry);

-- etldoc: osm_important_waterway_linestring_gen1 -> osm_important_waterway_linestring_gen2
CREATE MATERIALIZED VIEW osm_important_waterway_linestring_gen2 AS (
    SELECT ST_Simplify(geometry, 100) AS geometry, name
    FROM osm_important_waterway_linestring_gen1
    WHERE ST_Length(geometry) > 4000
) WITH NO DATA;
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen2_geometry_idx ON osm_important_waterway_linestring_gen2 USING gist(geometry);

-- etldoc: osm_important_waterway_linestring_gen2 -> osm_important_waterway_linestring_gen3
CREATE MATERIALIZED VIEW osm_important_waterway_linestring_gen3 AS (
    SELECT ST_Simplify(geometry, 200) AS geometry, name
    FROM osm_important_waterway_linestring_gen2
    WHERE ST_Length(geometry) > 8000
) WITH NO DATA;
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen3_geometry_idx ON osm_important_waterway_linestring_gen3 USING gist(geometry);

-- Handle updates

CREATE SCHEMA waterway;

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
    RAISE LOG 'Refresh transportation_name';
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring;
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring_gen1;
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring_gen2;
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring_gen3;
    DELETE FROM waterway.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER waterway.trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_waterway_linestring
    FOR EACH STATEMENT
    EXECUTE PROCEDURE waterway.flag();

CREATE CONSTRAINT TRIGGER waterway.trigger_refresh
    AFTER INSERT ON waterway.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE waterway.refresh();



