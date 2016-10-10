CREATE OR REPLACE VIEW water_z0 AS (
    SELECT geom, 'ocean' AS class FROM ne_110m_ocean
    UNION ALL
    SELECT geom, 'lake' AS class FROM ne_110m_lakes
);

CREATE OR REPLACE VIEW water_z1 AS (
    SELECT geom, 'ocean' AS class FROM ne_110m_ocean
    UNION ALL
    SELECT geom, 'lake' AS class FROM ne_110m_lakes
);

CREATE OR REPLACE VIEW water_z2 AS (
    SELECT geom, 'ocean' AS class FROM ne_50m_ocean
    UNION ALL
    SELECT geom, 'lake' AS class FROM ne_110m_lakes
);

CREATE OR REPLACE VIEW water_z3 AS (
    SELECT geom, 'ocean' AS class FROM ne_50m_ocean
    UNION ALL
    SELECT geom, 'lake' AS class FROM ne_110m_lakes
    UNION ALL
    SELECT geom, 'river' AS class FROM ne_110m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

CREATE OR REPLACE VIEW water_z4 AS (
    SELECT geom, 'ocean' AS class FROM ne_50m_ocean
    UNION ALL
    SELECT geom, 'lake' AS class FROM ne_50m_lakes
    UNION ALL
    SELECT geom, 'river' AS class FROM ne_50m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

CREATE OR REPLACE VIEW water_z5 AS (
    SELECT geom, 'ocean' AS class FROM ne_10m_ocean
    UNION ALL
    SELECT geom, 'lake' AS class FROM ne_10m_lakes
    UNION ALL
    SELECT geom, 'river' AS class FROM ne_50m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

CREATE OR REPLACE VIEW water_z6 AS (
    SELECT geom, 'ocean' AS class FROM ne_10m_ocean
    UNION ALL
    SELECT geom, 'lake' AS class FROM ne_10m_lakes
    UNION ALL
    SELECT geom, 'river' AS class FROM ne_10m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

CREATE TABLE IF NOT EXISTS water_z7 AS (
    SELECT geom, 'ocean' AS class FROM ne_10m_ocean
    UNION ALL
    SELECT geometry AS geom, 'lake' AS class FROM osm_water_polygon_gen3
    UNION ALL
    SELECT geom, 'river' AS class FROM ne_10m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);
CREATE INDEX IF NOT EXISTS water_z7_geom_idx ON water_z7 USING gist(geom);

CREATE TABLE IF NOT EXISTS water_z8 AS (
    SELECT geom, 'ocean' AS class FROM ne_10m_ocean
    UNION ALL
    SELECT geometry AS geom, 'lake' AS class FROM osm_water_polygon_gen2
    UNION ALL
    SELECT ST_Simplify(geometry, 200) AS geom, waterway AS class FROM osm_water_linestring
    WHERE waterway IN ('river') AND ST_Length(geometry) > 10000
);
CREATE INDEX IF NOT EXISTS water_z8_geom_idx ON water_z8 USING gist(geom);

CREATE TABLE IF NOT EXISTS water_z9 AS (
    SELECT geometry AS geom, 'lake' AS class FROM osm_water_polygon_gen1
    UNION ALL
    SELECT ST_Simplify(geometry, 100) AS geom, waterway AS class FROM osm_water_linestring
    WHERE waterway IN ('river') AND ST_Length(geometry) > 5000
);
CREATE INDEX IF NOT EXISTS water_z9_geom_idx ON water_z9 USING gist(geom);

CREATE OR REPLACE VIEW water_z11 AS (
    SELECT geometry AS geom, 'lake' AS class FROM osm_water_polygon WHERE area > 40000
    UNION ALL
    SELECT geometry AS geom, waterway AS class FROM osm_water_linestring
    WHERE waterway IN ('river') AND ST_Length(geometry) > 5000
);

CREATE OR REPLACE VIEW water_z12 AS (
    SELECT geometry AS geom, 'lake' AS class FROM osm_water_polygon WHERE area > 10000
    UNION ALL
    SELECT geometry AS geom, waterway AS class FROM osm_water_linestring
    WHERE waterway IN ('river', 'canal') OR (waterway = 'stream' AND ST_Length(geometry) > 1000)
);

CREATE OR REPLACE VIEW water_z13 AS (
    SELECT geometry AS geom, 'lake' AS class FROM osm_water_polygon WHERE area > 5000
    UNION ALL
    SELECT geometry AS geom, waterway AS class FROM osm_water_linestring
    WHERE waterway IN ('river', 'canal', 'stream', 'drain', 'ditch') AND ST_Length(geometry) > 300
);

CREATE OR REPLACE VIEW water_z14 AS (
    SELECT geometry AS geom, 'lake' AS class FROM osm_water_polygon
    UNION ALL
    SELECT geometry AS geom, waterway AS class FROM osm_water_linestring
);

CREATE OR REPLACE FUNCTION layer_water (bbox geometry, zoom_level int)
RETURNS TABLE(geom geometry, class text) AS $$
    SELECT geom, class FROM (
        SELECT * FROM water_z0 WHERE zoom_level = 0
        UNION ALL
        SELECT * FROM water_z1 WHERE zoom_level = 1
        UNION ALL
        SELECT * FROM water_z2 WHERE zoom_level = 2
        UNION ALL
        SELECT * FROM water_z3 WHERE zoom_level = 3
        UNION ALL
        SELECT * FROM water_z4 WHERE zoom_level = 4
        UNION ALL
        SELECT * FROM water_z5 WHERE zoom_level = 5
        UNION ALL
        SELECT * FROM water_z6 WHERE zoom_level = 6
        UNION ALL
        SELECT * FROM water_z7 WHERE zoom_level = 7
        UNION ALL
        SELECT * FROM water_z8 WHERE zoom_level = 8
        UNION ALL
        SELECT * FROM water_z9 WHERE zoom_level BETWEEN 9 AND 10
        UNION ALL
        SELECT * FROM water_z11 WHERE zoom_level = 11
        UNION ALL
        SELECT * FROM water_z12 WHERE zoom_level = 12
        UNION ALL
        SELECT * FROM water_z13 WHERE zoom_level = 13
        UNION ALL
        SELECT * FROM water_z14 WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geom && bbox;
$$ LANGUAGE SQL IMMUTABLE;
