
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
);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_geometry_idx ON osm_important_waterway_linestring USING gist(geometry);

-- etldoc: osm_important_waterway_linestring -> osm_important_waterway_linestring_gen1
CREATE MATERIALIZED VIEW osm_important_waterway_linestring_gen1 AS (
    SELECT ST_Simplify(geometry, 60) AS geometry, name
    FROM osm_important_waterway_linestring
    WHERE ST_Length(geometry) > 1000
);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen1_geometry_idx ON osm_important_waterway_linestring_gen1 USING gist(geometry);

-- etldoc: osm_important_waterway_linestring_gen1 -> osm_important_waterway_linestring_gen2
CREATE MATERIALIZED VIEW osm_important_waterway_linestring_gen2 AS (
    SELECT ST_Simplify(geometry, 100) AS geometry, name
    FROM osm_important_waterway_linestring_gen1
    WHERE ST_Length(geometry) > 4000
);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen2_geometry_idx ON osm_important_waterway_linestring_gen2 USING gist(geometry);

-- etldoc: osm_important_waterway_linestring_gen2 -> osm_important_waterway_linestring_gen3
CREATE MATERIALIZED VIEW osm_important_waterway_linestring_gen3 AS (
    SELECT ST_Simplify(geometry, 200) AS geometry, name
    FROM osm_important_waterway_linestring_gen2
    WHERE ST_Length(geometry) > 8000
);
CREATE INDEX IF NOT EXISTS osm_important_waterway_linestring_gen3_geometry_idx ON osm_important_waterway_linestring_gen3 USING gist(geometry);

--- Triggers

CREATE OR REPLACE FUNCTION refresh_osm_important_waterway_linestring() RETURNS trigger AS
  $BODY$
  BEGIN
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring;
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring_gen1;
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring_gen2;
    REFRESH MATERIALIZED VIEW osm_important_waterway_linestring_gen3;
      RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_refresh_osm_important_waterway_linestring
    AFTER INSERT OR UPDATE OR DELETE ON osm_waterway_linestring
    FOR EACH STATEMENT
    EXECUTE PROCEDURE refresh_osm_important_waterway_linestring();




