
-- We merge the waterways by name like the highways
-- This helps to drop not important rivers (since they do not have a name)
-- and also makes it possible to filter out too short rivers

-- etldoc: osm_waterway_linestring ->  osm_important_waterway_linestring
CREATE OR REPLACE FUNCTION osm_important_waterway_linestring(bbox geometry, zoom_level int)
    RETURNS TABLE(geometry geometry, name varchar) AS $$
    SELECT
        (ST_Dump(geometry)).geom AS geometry,
        name
    FROM (
        SELECT
            ST_LineMerge(ST_Union(geometry)) AS geometry,
            name
        FROM osm_waterway_linestring
        WHERE name <> '' AND waterway = 'river' AND geometry && bbox
        GROUP BY name
    ) AS waterway_union;
$$ LANGUAGE SQL IMMUTABLE;

-- etldoc: osm_important_waterway_linestring -> osm_important_waterway_linestring_gen1
CREATE OR REPLACE FUNCTION osm_important_waterway_linestring_gen1(bbox geometry, zoom_level int)
    RETURNS TABLE(geometry geometry, name varchar) AS $$
    SELECT ST_Simplify(geometry, 60) AS geometry, name
    FROM osm_important_waterway_linestring
    WHERE ST_Length(geometry) > 1000 AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

-- etldoc: osm_important_waterway_linestring_gen1 -> osm_important_waterway_linestring_gen2
CREATE OR REPLACE FUNCTION osm_important_waterway_linestring_gen2(bbox geometry, zoom_level int)
    RETURNS TABLE(geometry geometry, name varchar) AS $$
    SELECT ST_Simplify(geometry, 100) AS geometry, name
    FROM osm_important_waterway_linestring_gen1
    WHERE ST_Length(geometry) > 4000 AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

-- etldoc: osm_important_waterway_linestring_gen2 -> osm_important_waterway_linestring_gen3
CREATE OR REPLACE FUNCTION osm_important_waterway_linestring_gen3(bbox geometry, zoom_level int)
    RETURNS TABLE(geometry geometry, name varchar) AS $$
    SELECT ST_Simplify(geometry, 200) AS geometry, name
    FROM osm_important_waterway_linestring_gen2
    WHERE ST_Length(geometry) > 8000 AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
