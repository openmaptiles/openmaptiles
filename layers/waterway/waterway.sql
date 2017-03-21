
-- etldoc: ne_110m_rivers_lake_centerlines ->  waterway_z3
CREATE OR REPLACE VIEW waterway_z3 AS (
    SELECT geometry, 'river'::text AS class, NULL::text AS name, NULL::text AS name_en, NULL::text AS name_de
    FROM ne_110m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

-- etldoc: ne_50m_rivers_lake_centerlines ->  waterway_z4
CREATE OR REPLACE VIEW waterway_z4 AS (
    SELECT geometry, 'river'::text AS class, NULL::text AS name, NULL::text AS name_en, NULL::text AS name_de
    FROM ne_50m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

-- etldoc: ne_10m_rivers_lake_centerlines ->  waterway_z6
CREATE OR REPLACE VIEW waterway_z6 AS (
    SELECT geometry, 'river'::text AS class, NULL::text AS name, NULL::text AS name_en, NULL::text AS name_de
    FROM ne_10m_rivers_lake_centerlines
    WHERE featurecla = 'River'
);

-- etldoc: osm_important_waterway_linestring_gen3 ->  waterway_z9
CREATE OR REPLACE VIEW waterway_z9 AS (
    SELECT geometry, 'river'::text AS class, name, name_en, name_de FROM osm_important_waterway_linestring_gen3
);

-- etldoc: osm_important_waterway_linestring_gen2 ->  waterway_z10
CREATE OR REPLACE VIEW waterway_z10 AS (
    SELECT geometry, 'river'::text AS class, name, name_en, name_de FROM osm_important_waterway_linestring_gen2
);

-- etldoc:osm_important_waterway_linestring_gen1 ->  waterway_z11
CREATE OR REPLACE VIEW waterway_z11 AS (
    SELECT geometry, 'river'::text AS class, name, name_en, name_de FROM osm_important_waterway_linestring_gen1
);

-- etldoc: osm_waterway_linestring ->  waterway_z12
CREATE OR REPLACE VIEW waterway_z12 AS (
    SELECT geometry, waterway AS class, name, name_en, name_de FROM osm_waterway_linestring
    WHERE waterway IN ('river', 'canal')
);

-- etldoc: osm_waterway_linestring ->  waterway_z13
CREATE OR REPLACE VIEW waterway_z13 AS (
    SELECT geometry, waterway::text AS class, name, name_en, name_de FROM osm_waterway_linestring
    WHERE waterway IN ('river', 'canal', 'stream', 'drain', 'ditch')
);

-- etldoc: osm_waterway_linestring ->  waterway_z14
CREATE OR REPLACE VIEW waterway_z14 AS (
    SELECT geometry, waterway::text AS class, name, name_en, name_de FROM osm_waterway_linestring
);

-- etldoc: layer_waterway[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_waterway | <z3> z3 |<z4_5> z4-z5 |<z6_8> z6-8 | <z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14> z14+" ];

CREATE OR REPLACE FUNCTION layer_waterway(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, class text, name text, name_en text, name_de text) AS $$
    SELECT geometry, class,
        NULLIF(name, '') AS name,
        COALESCE(NULLIF(name_en, ''), name) AS name_en,
        COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de
    FROM (
        -- etldoc: waterway_z3 ->  layer_waterway:z3
        SELECT * FROM waterway_z3 WHERE zoom_level = 3
        UNION ALL
        -- etldoc: waterway_z4 ->  layer_waterway:z4_5
        SELECT * FROM waterway_z4 WHERE zoom_level BETWEEN 4 AND 5
        UNION ALL
        -- etldoc: waterway_z6 ->  layer_waterway:z6_8
        SELECT * FROM waterway_z6 WHERE zoom_level BETWEEN 6 AND 8
        UNION ALL
        -- etldoc: waterway_z9 ->  layer_waterway:z9
        SELECT * FROM waterway_z9 WHERE zoom_level = 9
        UNION ALL
        -- etldoc: waterway_z10 ->  layer_waterway:z10
        SELECT * FROM waterway_z10 WHERE zoom_level = 10
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
        -- etldoc: waterway_z14 ->  layer_waterway:z14
        SELECT * FROM waterway_z14 WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
