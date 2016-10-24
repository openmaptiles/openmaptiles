CREATE OR REPLACE VIEW waterway_z3 AS (
    SELECT geom AS geometry, 'river' AS class FROM ne_110m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

CREATE OR REPLACE VIEW waterway_z4 AS (
    SELECT geom AS geometry, 'river' AS class FROM ne_50m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

CREATE OR REPLACE VIEW waterway_z6 AS (
    SELECT geom AS geometry, 'river' AS class FROM ne_10m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

CREATE OR REPLACE VIEW waterway_z8 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
    WHERE waterway IN ('river') AND ST_Length(geometry) > 10000
);

CREATE OR REPLACE VIEW waterway_z9 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
    WHERE waterway IN ('river') AND ST_Length(geometry) > 5000
);

CREATE OR REPLACE VIEW waterway_z11 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
    WHERE waterway IN ('river') AND ST_Length(geometry) > 5000
);

CREATE OR REPLACE VIEW waterway_z12 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
    WHERE waterway IN ('river', 'canal') OR (waterway = 'stream' AND ST_Length(geometry) > 1000)
);

CREATE OR REPLACE VIEW waterway_z13 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
    WHERE waterway IN ('river', 'canal', 'stream', 'drain', 'ditch') AND ST_Length(geometry) > 300
);

CREATE OR REPLACE VIEW waterway_z14 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
);

CREATE OR REPLACE FUNCTION layer_waterway(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, class text) AS $$
    SELECT geometry, class FROM (
        SELECT * FROM waterway_z3 WHERE zoom_level = 3
        UNION ALL
        SELECT * FROM waterway_z4 WHERE zoom_level BETWEEN 4 AND 5
        UNION ALL
        SELECT * FROM waterway_z6 WHERE zoom_level BETWEEN 6 AND 7
        UNION ALL
        SELECT * FROM waterway_z8 WHERE zoom_level = 8
        UNION ALL
        SELECT * FROM waterway_z9 WHERE zoom_level BETWEEN 9 AND 10
        UNION ALL
        SELECT * FROM waterway_z11 WHERE zoom_level = 11
        UNION ALL
        SELECT * FROM waterway_z12 WHERE zoom_level = 12
        UNION ALL
        SELECT * FROM waterway_z13 WHERE zoom_level = 13
        UNION ALL
        SELECT * FROM waterway_z14 WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
