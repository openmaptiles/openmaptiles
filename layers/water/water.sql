-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS osm_ocean_polygon_gen1 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_ocean_polygon -> osm_ocean_polygon_gen1
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen1 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen1 AS (
  SELECT ST_Simplify(geometry, 20) AS geometry
  FROM osm_ocean_polygon
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen1_idx ON osm_ocean_polygon_gen1 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS osm_ocean_polygon_gen2 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_ocean_polygon -> osm_ocean_polygon_gen2
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen2 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen2 AS (
  SELECT ST_Simplify(geometry, 40) AS geometry
  FROM osm_ocean_polygon
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen2_idx ON osm_ocean_polygon_gen2 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS osm_ocean_polygon_gen3 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_ocean_polygon -> osm_ocean_polygon_gen3
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen3 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen3 AS (
  SELECT ST_Simplify(geometry, 80) AS geometry
  FROM osm_ocean_polygon
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen3_idx ON osm_ocean_polygon_gen3 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS osm_ocean_polygon_gen4 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_ocean_polygon -> osm_ocean_polygon_gen4
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen4 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen4 AS (
  SELECT ST_Simplify(geometry, 160) AS geometry
  FROM osm_ocean_polygon
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen4_idx ON osm_ocean_polygon_gen4 USING gist (geometry);



CREATE OR REPLACE FUNCTION water_class(waterway TEXT) RETURNS TEXT AS $$
    SELECT CASE
           %%FIELD_MAPPING: class %%
           ELSE 'river'
   END;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION waterway_brunnel(is_bridge BOOL, is_tunnel BOOL) RETURNS TEXT AS $$
    SELECT CASE
        WHEN is_bridge THEN 'bridge'
        WHEN is_tunnel THEN 'tunnel'
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;



CREATE OR REPLACE VIEW water_z0 AS (
    -- etldoc:  ne_110m_ocean ->  water_z0
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM ne_110m_ocean
    UNION ALL
    -- etldoc:  ne_110m_lakes ->  water_z0
    SELECT geometry,
        'lake'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM ne_110m_lakes
);

CREATE OR REPLACE VIEW water_z1 AS (
    -- etldoc:  ne_110m_ocean ->  water_z1
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM ne_110m_ocean
    UNION ALL
    -- etldoc:  ne_110m_lakes ->  water_z1
    SELECT geometry,
        'lake'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM ne_110m_lakes
);

CREATE OR REPLACE VIEW water_z2 AS (
    -- etldoc:  ne_50m_ocean ->  water_z2
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM ne_50m_ocean
    UNION ALL
    -- etldoc:  ne_50m_lakes ->  water_z2
    SELECT geometry,
        'lake'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM ne_50m_lakes
);

CREATE OR REPLACE VIEW water_z4 AS (
    -- etldoc:  ne_50m_ocean ->  water_z4
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM ne_50m_ocean
    UNION ALL
    -- etldoc:  ne_10m_lakes ->  water_z4
    SELECT geometry,
        'lake'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM ne_10m_lakes
);

CREATE OR REPLACE VIEW water_z5 AS (
    -- etldoc:  ne_10m_ocean ->  water_z5
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM ne_10m_ocean
    UNION ALL
    -- etldoc:  ne_10m_lakes ->  water_z5
    SELECT geometry,
        'lake'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM ne_10m_lakes
);

CREATE OR REPLACE VIEW water_z6 AS (
    -- etldoc:  osm_ocean_polygon_gen4 ->  water_z6
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_ocean_polygon_gen4
    UNION ALL
   -- etldoc:  osm_water_polygon_gen6 ->  water_z6
    SELECT geometry,
        water_class(waterway) AS class,
        is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_water_polygon_gen6
    WHERE "natural" != 'bay'
);

CREATE OR REPLACE VIEW water_z7 AS (
    -- etldoc:  osm_ocean_polygon_gen4 ->  water_z7
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_ocean_polygon_gen4
    UNION ALL
    -- etldoc:  osm_water_polygon_gen5 ->  water_z7
    SELECT geometry,
        water_class(waterway) AS class,
        is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_water_polygon_gen5
    WHERE "natural" != 'bay'
);

CREATE OR REPLACE VIEW water_z8 AS (
    -- etldoc:  osm_ocean_polygon_gen4 ->  water_z8
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_ocean_polygon_gen4
    UNION ALL
    -- etldoc:  osm_water_polygon_gen4 ->  water_z8
    SELECT geometry,
        water_class(waterway) AS class,
        is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_water_polygon_gen4
    WHERE "natural" != 'bay'
);

CREATE OR REPLACE VIEW water_z9 AS (
    -- etldoc:  osm_ocean_polygon_gen3 ->  water_z9
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_ocean_polygon_gen3
    UNION ALL
    -- etldoc:  osm_water_polygon_gen3 ->  water_z9
    SELECT geometry,
        water_class(waterway) AS class,
        is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_water_polygon_gen3
    WHERE "natural" != 'bay'
);

CREATE OR REPLACE VIEW water_z10 AS (
    -- etldoc:  osm_ocean_polygon_gen2 ->  water_z10
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_ocean_polygon_gen2
    UNION ALL
    -- etldoc:  osm_water_polygon_gen2 ->  water_z10
    SELECT geometry,
        water_class(waterway) AS class,
        is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_water_polygon_gen2
    WHERE "natural" != 'bay'
);

CREATE OR REPLACE VIEW water_z11 AS (
    -- etldoc:  osm_ocean_polygon_gen1 ->  water_z11
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_ocean_polygon_gen1
    UNION ALL
    -- etldoc:  osm_water_polygon_gen1 ->  water_z11
    SELECT geometry,
        water_class(waterway) AS class,
        is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_water_polygon_gen1
    WHERE "natural" != 'bay'
);

CREATE OR REPLACE VIEW water_z12 AS (
    -- etldoc:  osm_ocean_polygon_gen1 ->  water_z12
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_ocean_polygon
    UNION ALL
    -- etldoc:  osm_water_polygon ->  water_z12
    SELECT geometry,
        water_class(waterway) AS class,
        is_intermittent,
        is_bridge,
        is_tunnel
    FROM osm_water_polygon
    WHERE "natural" != 'bay'
);

CREATE OR REPLACE VIEW water_z13 AS (
    -- etldoc:  osm_ocean_polygon ->  water_z13
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_ocean_polygon
    UNION ALL
    -- etldoc:  osm_water_polygon ->  water_z13
    SELECT geometry,
        water_class(waterway) AS class,
        is_intermittent,
        is_bridge,
        is_tunnel
    FROM osm_water_polygon
    WHERE "natural" != 'bay'
);

CREATE OR REPLACE VIEW water_z14 AS (
    -- etldoc:  osm_ocean_polygon ->  water_z14
    SELECT geometry,
        'ocean'::text AS class,
        NULL::boolean AS is_intermittent,
        NULL::boolean AS is_bridge,
        NULL::boolean AS is_tunnel
    FROM osm_ocean_polygon
    UNION ALL
    -- etldoc:  osm_water_polygon ->  water_z14
    SELECT geometry,
        water_class(waterway) AS class,
        is_intermittent,
        is_bridge,
        is_tunnel
    FROM osm_water_polygon
    WHERE "natural" != 'bay'
);

-- etldoc: layer_water [shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_water |<z0> z0|<z1>z1|<z2>z2|<z3>z3 |<z4> z4|<z5>z5|<z6>z6|<z7>z7| <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_water (bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, class text, brunnel text, intermittent int) AS $$
    SELECT geometry,
        class::text,
        waterway_brunnel(is_bridge, is_tunnel) AS brunnel,
        is_intermittent::int AS intermittent
    FROM (
        -- etldoc: water_z0 ->  layer_water:z0
        SELECT * FROM water_z0 WHERE zoom_level = 0
        UNION ALL
        -- etldoc: water_z1 ->  layer_water:z1
        SELECT * FROM water_z1 WHERE zoom_level = 1
        UNION ALL
        -- etldoc: water_z2 ->  layer_water:z2
        -- etldoc: water_z2 ->  layer_water:z3
        SELECT * FROM water_z2 WHERE zoom_level BETWEEN 2 AND 3
        UNION ALL
        -- etldoc: water_z4 ->  layer_water:z4
        SELECT * FROM water_z4 WHERE zoom_level = 4
        UNION ALL
        -- etldoc: water_z5 ->  layer_water:z5
        SELECT * FROM water_z5 WHERE zoom_level = 5
        UNION ALL
        -- etldoc: water_z6 ->  layer_water:z6
        SELECT * FROM water_z6 WHERE zoom_level = 6
        UNION ALL
        -- etldoc: water_z7 ->  layer_water:z7
        SELECT * FROM water_z7 WHERE zoom_level = 7
        UNION ALL
        -- etldoc: water_z8 ->  layer_water:z8
        SELECT * FROM water_z8 WHERE zoom_level = 8
        UNION ALL
        -- etldoc: water_z9 ->  layer_water:z9
        SELECT * FROM water_z9 WHERE zoom_level = 9
        UNION ALL
        -- etldoc: water_z10 ->  layer_water:z10
        SELECT * FROM water_z10 WHERE zoom_level = 10
        UNION ALL
        -- etldoc: water_z11 ->  layer_water:z11
        SELECT * FROM water_z11 WHERE zoom_level = 11
        UNION ALL
        -- etldoc: water_z12 ->  layer_water:z12
        SELECT * FROM water_z12 WHERE zoom_level = 12
        UNION ALL
        -- etldoc: water_z13 ->  layer_water:z13
        SELECT * FROM water_z13 WHERE zoom_level = 13
        UNION ALL
        -- etldoc: water_z14 ->  layer_water:z14_
        SELECT * FROM water_z14 WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
