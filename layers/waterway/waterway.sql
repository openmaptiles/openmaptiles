
-- etldoc: ne_110m_rivers_lake_centerlines ->  waterway_z3
CREATE OR REPLACE VIEW waterway_z3 AS (
    SELECT geom AS geometry, 'river' AS class FROM ne_110m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

-- etldoc: ne_50m_rivers_lake_centerlines ->  waterway_z4
CREATE OR REPLACE VIEW waterway_z4 AS (
    SELECT geom AS geometry, 'river' AS class FROM ne_50m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

-- etldoc: ne_10m_rivers_lake_centerlines ->  waterway_z6
CREATE OR REPLACE VIEW waterway_z6 AS (
    SELECT geom AS geometry, 'river' AS class FROM ne_10m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

-- etldoc: osm_waterway_linestring ->  waterway_z8
CREATE OR REPLACE VIEW waterway_z8 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
    WHERE waterway IN ('river') AND ST_Length(geometry) > 10000
);

-- etldoc: osm_waterway_linestring ->  waterway_z9
CREATE OR REPLACE VIEW waterway_z9 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
    WHERE waterway IN ('river') AND ST_Length(geometry) > 5000
);

-- etldoc: osm_waterway_linestring ->  waterway_z11
CREATE OR REPLACE VIEW waterway_z11 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
    WHERE waterway IN ('river') AND ST_Length(geometry) > 5000
);

-- etldoc: osm_waterway_linestring ->  waterway_z12
CREATE OR REPLACE VIEW waterway_z12 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
    WHERE waterway IN ('river', 'canal') OR (waterway = 'stream' AND ST_Length(geometry) > 1000)
);

-- etldoc: osm_waterway_linestring ->  waterway_z13
CREATE OR REPLACE VIEW waterway_z13 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
    WHERE waterway IN ('river', 'canal', 'stream', 'drain', 'ditch') AND ST_Length(geometry) > 300
);

-- etldoc: osm_waterway_linestring ->  waterway_z14
CREATE OR REPLACE VIEW waterway_z14 AS (
    SELECT geometry, waterway AS class FROM osm_waterway_linestring
);


-- etldoc: layer_waterway[shape=record fillcolor=lightpink, style="rounded,filled",  
-- etldoc:     label="layer_waterway | <z3> z3 |<z4_5> z4_5 |<z6_7> z6_7 | <z8> z8 |<z9_10> z9_10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14_" ] ;

CREATE OR REPLACE FUNCTION layer_waterway(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, class text) AS $$
    SELECT geometry, class FROM (
        -- etldoc: waterway_z3 ->  layer_waterway:z3        
        SELECT * FROM waterway_z3 WHERE zoom_level = 3
        UNION ALL
        -- etldoc: waterway_z4 ->  layer_waterway:z4_5        
        SELECT * FROM waterway_z4 WHERE zoom_level BETWEEN 4 AND 5
        UNION ALL
        -- etldoc: waterway_z6 ->  layer_waterway:z6_7           
        SELECT * FROM waterway_z6 WHERE zoom_level BETWEEN 6 AND 7
        UNION ALL
        -- etldoc: waterway_z8 ->  layer_waterway:z8           
        SELECT * FROM waterway_z8 WHERE zoom_level = 8
        UNION ALL
        -- etldoc: waterway_z9 ->  layer_waterway:z9_10        
        SELECT * FROM waterway_z9 WHERE zoom_level BETWEEN 9 AND 10
        UNION ALL
        -- etldoc: waterway_z11 ->  layer_waterway:z11        
        SELECT * FROM waterway_z11 WHERE zoom_level = 11
        UNION ALL
        -- etldoc: waterway_z12 ->  layer_waterway:z12        
        SELECT * FROM waterway_z12 WHERE zoom_level = 12
        UNION ALL
        -- etldoc: waterway_z13 ->  layer_waterway:z13        
        SELECT * FROM waterway_z13 WHERE zoom_level = 13
        UNION ALL
        -- etldoc: waterway_z14 ->  layer_waterway:z14_        
        SELECT * FROM waterway_z14 WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
