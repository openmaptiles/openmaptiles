CREATE OR REPLACE FUNCTION waterway_brunnel(is_bridge bool, is_tunnel bool) RETURNS text AS
$$
SELECT CASE
           WHEN is_bridge THEN 'bridge'
           WHEN is_tunnel THEN 'tunnel'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;
-- ne_110m_rivers_lake_centerlines
-- etldoc: ne_110m_rivers_lake_centerlines ->  ne_110m_rivers_lake_centerlines_gen_z3
DROP MATERIALIZED VIEW IF EXISTS ne_110m_rivers_lake_centerlines_gen_z3 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_rivers_lake_centerlines_gen_z3 AS
(
SELECT ST_Simplify(geometry, ZRes(5)) as geometry,
       'river'::text AS class,
       NULL::text AS name,
       NULL::text AS name_en,
       NULL::text AS name_de,
       NULL::hstore AS tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM ne_110m_rivers_lake_centerlines
WHERE featurecla = 'River'
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_rivers_lake_centerlines_gen_z3_idx ON ne_110m_rivers_lake_centerlines_gen_z3 USING gist (geometry);

-- ne_50m_rivers_lake_centerlines
-- etldoc: ne_50m_rivers_lake_centerlines ->  ne_50m_rivers_lake_centerlines_gen_z5
DROP MATERIALIZED VIEW IF EXISTS ne_50m_rivers_lake_centerlines_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_rivers_lake_centerlines_gen_z5 AS
(
SELECT ST_Simplify(geometry, ZRes(7)) as geometry,
       'river'::text AS class,
       NULL::text AS name,
       NULL::text AS name_en,
       NULL::text AS name_de,
       NULL::hstore AS tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM ne_50m_rivers_lake_centerlines
WHERE featurecla = 'River'
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_rivers_lake_centerlines_gen_z5_idx ON ne_50m_rivers_lake_centerlines_gen_z5 USING gist (geometry);

-- etldoc: ne_50m_rivers_lake_centerlines_gen_z5 ->  ne_50m_rivers_lake_centerlines_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_50m_rivers_lake_centerlines_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_rivers_lake_centerlines_gen_z4 AS
(
SELECT ST_Simplify(geometry, ZRes(6)) as geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_50m_rivers_lake_centerlines_gen_z5
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_rivers_lake_centerlines_gen_z4_idx ON ne_50m_rivers_lake_centerlines_gen_z4 USING gist (geometry);

-- ne_10m_rivers_lake_centerlines
-- etldoc: ne_10m_rivers_lake_centerlines ->  ne_10m_rivers_lake_centerlines_gen_z8
DROP MATERIALIZED VIEW IF EXISTS ne_10m_rivers_lake_centerlines_gen_z8 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_rivers_lake_centerlines_gen_z8 AS
(
SELECT ST_Simplify(geometry, ZRes(10)) as geometry,
       'river'::text AS class,
       NULL::text AS name,
       NULL::text AS name_en,
       NULL::text AS name_de,
       NULL::hstore AS tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM ne_10m_rivers_lake_centerlines
WHERE featurecla = 'River'
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_rivers_lake_centerlines_gen_z8_idx ON ne_10m_rivers_lake_centerlines_gen_z8 USING gist (geometry);

-- etldoc: ne_10m_rivers_lake_centerlines_gen_z8 ->  ne_10m_rivers_lake_centerlines_gen_z7
DROP MATERIALIZED VIEW IF EXISTS ne_10m_rivers_lake_centerlines_gen_z7 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_rivers_lake_centerlines_gen_z7 AS
(
SELECT ST_Simplify(geometry, ZRes(9)) as geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_10m_rivers_lake_centerlines_gen_z8
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_rivers_lake_centerlines_gen_z7_idx ON ne_10m_rivers_lake_centerlines_gen_z7 USING gist (geometry);

-- etldoc: ne_10m_rivers_lake_centerlines_gen_z7 ->  ne_10m_rivers_lake_centerlines_gen_z6
DROP MATERIALIZED VIEW IF EXISTS ne_10m_rivers_lake_centerlines_gen_z6 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_rivers_lake_centerlines_gen_z6 AS
(
SELECT ST_Simplify(geometry, ZRes(8)) as geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_10m_rivers_lake_centerlines_gen_z7
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_rivers_lake_centerlines_gen_z6_idx ON ne_10m_rivers_lake_centerlines_gen_z6 USING gist (geometry);


-- etldoc: ne_110m_rivers_lake_centerlines_gen_z3 ->  waterway_z3
CREATE OR REPLACE VIEW waterway_z3 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_110m_rivers_lake_centerlines_gen_z3
    );

-- etldoc: ne_50m_rivers_lake_centerlines_gen_z4 ->  waterway_z4
CREATE OR REPLACE VIEW waterway_z4 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_50m_rivers_lake_centerlines_gen_z4
    );

-- etldoc: ne_50m_rivers_lake_centerlines_gen_z5 ->  waterway_z5
CREATE OR REPLACE VIEW waterway_z5 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_50m_rivers_lake_centerlines_gen_z5
    );

-- etldoc: ne_10m_rivers_lake_centerlines_gen_z6 ->  waterway_z6
CREATE OR REPLACE VIEW waterway_z6 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_10m_rivers_lake_centerlines_gen_z6
    );

-- etldoc: ne_10m_rivers_lake_centerlines_gen_z7 ->  waterway_z7
CREATE OR REPLACE VIEW waterway_z7 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_10m_rivers_lake_centerlines_gen_z7
    );

    -- etldoc: ne_10m_rivers_lake_centerlines_gen_z8 ->  waterway_z8
CREATE OR REPLACE VIEW waterway_z8 AS
(
SELECT geometry,
       class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM ne_10m_rivers_lake_centerlines_gen_z8
    );

-- etldoc: osm_important_waterway_linestring_gen_z9 ->  waterway_z9
CREATE OR REPLACE VIEW waterway_z9 AS
(
SELECT geometry,
       'river'::text AS class,
       name,
       name_en,
       name_de,
       tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM osm_important_waterway_linestring_gen_z9
    );

-- etldoc: osm_important_waterway_linestring_gen_z10 ->  waterway_z10
CREATE OR REPLACE VIEW waterway_z10 AS
(
SELECT geometry,
       'river'::text AS class,
       name,
       name_en,
       name_de,
       tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM osm_important_waterway_linestring_gen_z10
    );

-- etldoc:osm_important_waterway_linestring_gen_z11 ->  waterway_z11
CREATE OR REPLACE VIEW waterway_z11 AS
(
SELECT geometry,
       'river'::text AS class,
       name,
       name_en,
       name_de,
       tags,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel,
       NULL::boolean AS is_intermittent
FROM osm_important_waterway_linestring_gen_z11
    );

-- etldoc: osm_waterway_linestring ->  waterway_z12
CREATE OR REPLACE VIEW waterway_z12 AS
(
SELECT geometry,
       waterway::text AS class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM osm_waterway_linestring
WHERE waterway IN ('river', 'canal')
    );

-- etldoc: osm_waterway_linestring ->  waterway_z13
CREATE OR REPLACE VIEW waterway_z13 AS
(
SELECT geometry,
       waterway::text AS class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM osm_waterway_linestring
WHERE waterway IN ('river', 'canal', 'stream', 'drain', 'ditch')
    );

-- etldoc: osm_waterway_linestring ->  waterway_z14
CREATE OR REPLACE VIEW waterway_z14 AS
(
SELECT geometry,
       waterway::text AS class,
       name,
       name_en,
       name_de,
       tags,
       is_bridge,
       is_tunnel,
       is_intermittent
FROM osm_waterway_linestring
    );

-- etldoc: layer_waterway[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc: label="layer_waterway | <z3> z3 |<z4> z4 |<z5> z5 |<z6> z6 |<z7> z7 |<z8> z8 | <z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14> z14+" ];

CREATE OR REPLACE FUNCTION layer_waterway(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                geometry     geometry,
                class        text,
                name         text,
                name_en      text,
                name_de      text,
                brunnel      text,
                intermittent int,
                tags         hstore
            )
AS
$$
SELECT geometry,
       class,
       NULLIF(name, '') AS name,
       COALESCE(NULLIF(name_en, ''), name) AS name_en,
       COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
       waterway_brunnel(is_bridge, is_tunnel) AS brunnel,
       is_intermittent::int AS intermittent,
       tags
FROM (
         -- etldoc: waterway_z3 ->  layer_waterway:z3
         SELECT *
         FROM waterway_z3
         WHERE zoom_level = 3
         UNION ALL
         -- etldoc: waterway_z4 ->  layer_waterway:z4
         SELECT *
         FROM waterway_z4
         WHERE zoom_level = 4
         UNION ALL
         -- etldoc: waterway_z5 ->  layer_waterway:z5
         SELECT *
         FROM waterway_z5
         WHERE zoom_level = 5
         UNION ALL
         -- etldoc: waterway_z6 ->  layer_waterway:z6
         SELECT *
         FROM waterway_z6
         WHERE zoom_level = 6
         UNION ALL
         -- etldoc: waterway_z7 ->  layer_waterway:z7
         SELECT *
         FROM waterway_z7
         WHERE zoom_level = 7
         UNION ALL
         -- etldoc: waterway_z8 ->  layer_waterway:z8
         SELECT *
         FROM waterway_z8
         WHERE zoom_level = 8
         UNION ALL
         -- etldoc: waterway_z9 ->  layer_waterway:z9
         SELECT *
         FROM waterway_z9
         WHERE zoom_level = 9
         UNION ALL
         -- etldoc: waterway_z10 ->  layer_waterway:z10
         SELECT *
         FROM waterway_z10
         WHERE zoom_level = 10
         UNION ALL
         -- etldoc: waterway_z11 ->  layer_waterway:z11
         SELECT *
         FROM waterway_z11
         WHERE zoom_level = 11
         UNION ALL
         -- etldoc: waterway_z12 ->  layer_waterway:z12
         SELECT *
         FROM waterway_z12
         WHERE zoom_level = 12
         UNION ALL
         -- etldoc: waterway_z13 ->  layer_waterway:z13
         SELECT *
         FROM waterway_z13
         WHERE zoom_level = 13
         UNION ALL
         -- etldoc: waterway_z14 ->  layer_waterway:z14
         SELECT *
         FROM waterway_z14
         WHERE zoom_level >= 14
     ) AS zoom_levels
WHERE geometry && bbox;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
