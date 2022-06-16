CREATE OR REPLACE FUNCTION water_class(waterway text, water text, leisure text) RETURNS text AS
$$
SELECT CASE
           WHEN waterway='riverbank' THEN 'river'
           %%FIELD_MAPPING: class %%
           ELSE 'lake'
           END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;


CREATE OR REPLACE FUNCTION waterway_brunnel(is_bridge bool, is_tunnel bool) RETURNS text AS
$$
SELECT CASE
           WHEN is_bridge THEN 'bridge'
           WHEN is_tunnel THEN 'tunnel'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Add ne_id for missing ne_50m_lakes.
UPDATE ne_50m_lakes SET ne_id = ne_10m_lakes.ne_id
FROM ne_50m_lakes lakes
LEFT JOIN ne_10m_lakes USING (wikidataid)
WHERE   ne_50m_lakes.wikidataid = ne_10m_lakes.wikidataid
    AND ne_50m_lakes.ne_id = 0;

-- Update ne_110_lakes ne_id where two lakes (Lake Onega) have identical attributes.
-- New ne_id is taken from ne_50m_lakes
UPDATE ne_110m_lakes SET ne_id = 1159126421
WHERE   ne_id = 1159113251
    AND ST_Area(geometry) < 10000000000;

-- Get matching osm id for natural earth id.
DROP MATERIALIZED VIEW IF EXISTS match_osm_ne_id CASCADE;
CREATE MATERIALIZED VIEW match_osm_ne_id AS
(
WITH name_match AS
    (
        -- Distinct on keeps just the first occurence -> order by 'area_ratio DESC'.
    SELECT DISTINCT ON (ne.ne_id) 
        ne.ne_id,
        osm.osm_id,
        (ST_Area(ST_Intersection(ne.geometry, osm.geometry))/ST_Area(ne.geometry)) AS area_ratio
    FROM ne_10m_lakes ne, osm_water_polygon_gen_z6 osm
    WHERE ne.name = osm.name 
        AND ST_Intersects(ne.geometry, osm.geometry)
    ORDER BY ne_id,
             area_ratio DESC
    ),
        -- Add lakes which are not match by name, but intersects. 
        -- Duplicity solves 'DISTICT ON' with 'area_ratio'.
    geom_match AS
    (SELECT DISTINCT ON (ne.ne_id) 
        ne.ne_id,
        osm.osm_id,
        (ST_Area(ST_Intersection(ne.geometry, osm.geometry))/ST_Area(ne.geometry)) AS area_ratio
	FROM ne_10m_lakes ne, osm_water_polygon_gen_z6 osm
	WHERE ST_Intersects(ne.geometry, osm.geometry)
        AND ne.ne_id NOT IN 
            (   SELECT ne_id 
                FROM name_match
            )
    ORDER BY ne_id,
             area_ratio DESC
    )
 
SELECT  ne_id,
        osm_id 
FROM name_match

UNION

SELECT  ne_id,
        osm_id 
FROM geom_match
);

-- ne_10m_ocean
-- etldoc:  ne_10m_ocean ->  ne_10m_ocean_gen_z5
DROP MATERIALIZED VIEW IF EXISTS ne_10m_ocean_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_ocean_gen_z5 AS
(
SELECT  NULL::integer AS id,
       (ST_Dump(ST_Simplify(geometry, ZRes(7)))).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_10m_ocean
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_ocean_gen_z5_idx ON ne_10m_ocean_gen_z5 USING gist (geometry);

-- ne_10m_lakes
-- etldoc:  ne_10m_lakes ->  ne_10m_lakes_gen_z5
DROP MATERIALIZED VIEW IF EXISTS ne_10m_lakes_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_lakes_gen_z5 AS
(
SELECT COALESCE(osm.osm_id, ne_id) AS id,
        -- Union fixing e.g. Lake Huron and Georgian Bay duplicity 
       (ST_Dump(ST_MakeValid(ST_Simplify(ST_Union(geometry), ZRes(7))))).geom AS geometry,
       'lake'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_10m_lakes
LEFT JOIN match_osm_ne_id osm USING (ne_id)
GROUP BY COALESCE(osm.osm_id, ne_id), is_intermittent, is_bridge, is_tunnel
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_lakes_gen_z5_idx ON ne_10m_lakes_gen_z5 USING gist (geometry);

-- etldoc:  ne_10m_lakes_gen_z5 ->  ne_10m_lakes_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_10m_lakes_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_lakes_gen_z4 AS
(
SELECT id,
       (ST_Dump(ST_MakeValid(ST_Simplify(geometry, ZRes(6))))).geom AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_10m_lakes_gen_z5
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_lakes_gen_z4_idx ON ne_10m_lakes_gen_z4 USING gist (geometry);

-- ne_50m_ocean
-- etldoc:  ne_50m_ocean ->  ne_50m_ocean_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_50m_ocean_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_ocean_gen_z4 AS
(
SELECT NULL::integer AS id,
       (ST_Dump(ST_Simplify(geometry, ZRes(6)))).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_50m_ocean
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_ocean_gen_z4_idx ON ne_50m_ocean_gen_z4 USING gist (geometry);

-- etldoc:  ne_50m_ocean_gen_z4 ->  ne_50m_ocean_gen_z3
DROP MATERIALIZED VIEW IF EXISTS ne_50m_ocean_gen_z3 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_ocean_gen_z3 AS
(
SELECT id,
       ST_Simplify(geometry, ZRes(5)) AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_ocean_gen_z4
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_ocean_gen_z3_idx ON ne_50m_ocean_gen_z3 USING gist (geometry);

-- etldoc:  ne_50m_ocean_gen_z3 ->  ne_50m_ocean_gen_z2
DROP MATERIALIZED VIEW IF EXISTS ne_50m_ocean_gen_z2 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_ocean_gen_z2 AS
(
SELECT id,
       ST_Simplify(geometry, ZRes(4)) AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_ocean_gen_z3
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_ocean_gen_z2_idx ON ne_50m_ocean_gen_z2 USING gist (geometry);

-- ne_50m_lakes
-- etldoc:  ne_50m_lakes ->  ne_50m_lakes_gen_z3
DROP MATERIALIZED VIEW IF EXISTS ne_50m_lakes_gen_z3 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_lakes_gen_z3 AS
(
SELECT COALESCE(osm.osm_id, ne_id) AS id,
       (ST_Dump(ST_MakeValid(ST_Simplify(geometry, ZRes(5))))).geom AS geometry,
       'lake'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_50m_lakes
LEFT JOIN match_osm_ne_id osm USING (ne_id)
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_lakes_gen_z3_idx ON ne_50m_lakes_gen_z3 USING gist (geometry);

-- etldoc:  ne_50m_lakes_gen_z3 ->  ne_50m_lakes_gen_z2
DROP MATERIALIZED VIEW IF EXISTS ne_50m_lakes_gen_z2 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_lakes_gen_z2 AS
(
SELECT id,
       (ST_Dump(ST_MakeValid(ST_Simplify(geometry, ZRes(4))))).geom AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_lakes_gen_z3
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_lakes_gen_z2_idx ON ne_50m_lakes_gen_z2 USING gist (geometry);

--ne_110m_ocean
-- etldoc:  ne_110m_ocean ->  ne_110m_ocean_gen_z1
DROP MATERIALIZED VIEW IF EXISTS ne_110m_ocean_gen_z1 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_ocean_gen_z1 AS
(
SELECT NULL::integer AS id,
       ST_Simplify(geometry, ZRes(3)) AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_110m_ocean
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_ocean_gen_z1_idx ON ne_110m_ocean_gen_z1 USING gist (geometry);

-- etldoc:  ne_110m_ocean_gen_z1 ->  ne_110m_ocean_gen_z0
DROP MATERIALIZED VIEW IF EXISTS ne_110m_ocean_gen_z0 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_ocean_gen_z0 AS
(
SELECT id,
       ST_Simplify(geometry, ZRes(2)) AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_ocean_gen_z1
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_ocean_gen_z0_idx ON ne_110m_ocean_gen_z0 USING gist (geometry);


-- ne_110m_lakes
-- etldoc:  ne_110m_lakes ->  ne_110m_lakes_gen_z1
DROP MATERIALIZED VIEW IF EXISTS ne_110m_lakes_gen_z1 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_lakes_gen_z1 AS
(
SELECT COALESCE(osm.osm_id, ne_id) AS id,
       (ST_Dump(ST_Simplify(geometry, ZRes(3)))).geom AS geometry,
       'lake'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM ne_110m_lakes
LEFT JOIN match_osm_ne_id osm USING (ne_id)
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_lakes_gen_z1_idx ON ne_110m_lakes_gen_z1 USING gist (geometry);

-- etldoc:  ne_110m_lakes_gen_z1 ->  ne_110m_lakes_gen_z0
DROP MATERIALIZED VIEW IF EXISTS ne_110m_lakes_gen_z0 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_lakes_gen_z0 AS
(
SELECT id,
       (ST_Dump(ST_Simplify(geometry, ZRes(2)))).geom AS geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_lakes_gen_z1
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_lakes_gen_z0_idx ON ne_110m_lakes_gen_z0 USING gist (geometry);

DROP MATERIALIZED VIEW IF EXISTS water_z6;
DROP MATERIALIZED VIEW IF EXISTS water_z7;
DROP MATERIALIZED VIEW IF EXISTS water_z8;
DROP MATERIALIZED VIEW IF EXISTS water_z9;
DROP MATERIALIZED VIEW IF EXISTS water_z10;
DROP MATERIALIZED VIEW IF EXISTS water_z11;
DROP MATERIALIZED VIEW IF EXISTS water_z12;

CREATE OR REPLACE VIEW water_z0 AS
(
-- etldoc:  ne_110m_ocean_gen_z0 ->  water_z0
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_ocean_gen_z0
UNION ALL
-- etldoc:  ne_110m_lakes_gen_z0 ->  water_z0
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_lakes_gen_z0
    );

CREATE OR REPLACE VIEW water_z1 AS
(
-- etldoc:  ne_110m_ocean_gen_z1 ->  water_z1
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_ocean_gen_z1
UNION ALL
-- etldoc:  ne_110m_lakes_gen_z1 ->  water_z1
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_110m_lakes_gen_z1
    );

CREATE OR REPLACE VIEW water_z2 AS
(
-- etldoc:  ne_50m_ocean_gen_z2 ->  water_z2
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_ocean_gen_z2
UNION ALL
-- etldoc:  ne_50m_lakes_gen_z2 ->  water_z2
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_lakes_gen_z2
    );

CREATE OR REPLACE VIEW water_z3 AS
(
-- etldoc:  ne_50m_ocean_gen_z3 ->  water_z3
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_ocean_gen_z3
UNION ALL
-- etldoc:  ne_50m_lakes_gen_z3 ->  water_z3
SELECT id, 
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_lakes_gen_z3
    );

CREATE OR REPLACE VIEW water_z4 AS
(
-- etldoc:  ne_50m_ocean_gen_z4 ->  water_z4
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_50m_ocean_gen_z4
UNION ALL
-- etldoc:  ne_10m_lakes_gen_z4 ->  water_z4
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_10m_lakes_gen_z4
    );


CREATE OR REPLACE VIEW water_z5 AS
(
-- etldoc:  ne_10m_ocean_gen_z5 ->  water_z5
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_10m_ocean_gen_z5
UNION ALL
-- etldoc:  ne_10m_lakes_gen_z5 ->  water_z5
SELECT id,
       geometry,
       class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM ne_10m_lakes_gen_z5
    );

CREATE MATERIALIZED VIEW water_z6 AS
(
-- etldoc:  osm_ocean_polygon_gen_z6 ->  water_z6
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z6
UNION ALL
-- etldoc:  osm_water_polygon_gen_z6 ->  water_z6
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z6
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z6 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z7 AS
(
-- etldoc:  osm_ocean_polygon_gen_z7 ->  water_z7
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z7
UNION ALL
-- etldoc:  osm_water_polygon_gen_z7 ->  water_z7
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z7
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z7 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z8 AS
(
-- etldoc:  osm_ocean_polygon_gen_z8 ->  water_z8
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z8
UNION ALL
-- etldoc:  osm_water_polygon_gen_z8 ->  water_z8
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z8
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z8 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z9 AS
(
-- etldoc:  osm_ocean_polygon_gen_z9 ->  water_z9
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z9
UNION ALL
-- etldoc:  osm_water_polygon_gen_z9 ->  water_z9
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z9
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z9 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z10 AS
(
-- etldoc:  osm_ocean_polygon_gen_z10 ->  water_z10
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z10
UNION ALL
-- etldoc:  osm_water_polygon_gen_z10 ->  water_z10
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z10
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z10 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z11 AS
(
-- etldoc:  osm_ocean_polygon_gen_z11 ->  water_z11
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z11
UNION ALL
-- etldoc:  osm_water_polygon_gen_z11 ->  water_z11
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z11
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z11 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z12 AS
(
-- etldoc:  osm_ocean_polygon_union ->  water_z12
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_union
UNION ALL
-- etldoc:  osm_water_polygon ->  water_z12
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM osm_water_polygon
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z12 USING gist(geometry);

-- etldoc: layer_water [shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_water |<z0> z0|<z1>z1|<z2>z2|<z3>z3 |<z4> z4|<z5>z5|<z6>z6|<z7>z7| <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12+" ] ;

CREATE OR REPLACE FUNCTION layer_water(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                id           bigint,
                geometry     geometry,
                class        text,
                brunnel      text,
                intermittent int
            )
AS
$$
SELECT id,
       geometry,
       class::text,
       waterway_brunnel(is_bridge, is_tunnel) AS brunnel,
       is_intermittent::int AS intermittent
FROM (
         -- etldoc: water_z0 ->  layer_water:z0
         SELECT *
         FROM water_z0
         WHERE zoom_level = 0
         UNION ALL
         -- etldoc: water_z1 ->  layer_water:z1
         SELECT *
         FROM water_z1
         WHERE zoom_level = 1
         UNION ALL
         -- etldoc: water_z2 ->  layer_water:z2
         SELECT *
         FROM water_z2
         WHERE zoom_level = 2
         UNION ALL
         -- etldoc: water_z3 ->  layer_water:z3
         SELECT *
         FROM water_z3
         WHERE zoom_level = 3
         UNION ALL
         -- etldoc: water_z4 ->  layer_water:z4
         SELECT *
         FROM water_z4
         WHERE zoom_level = 4
         UNION ALL
         -- etldoc: water_z5 ->  layer_water:z5
         SELECT *
         FROM water_z5
         WHERE zoom_level = 5
         UNION ALL
         -- etldoc: water_z6 ->  layer_water:z6
         SELECT *
         FROM water_z6
         WHERE zoom_level = 6
         UNION ALL
         -- etldoc: water_z7 ->  layer_water:z7
         SELECT *
         FROM water_z7
         WHERE zoom_level = 7
         UNION ALL
         -- etldoc: water_z8 ->  layer_water:z8
         SELECT *
         FROM water_z8
         WHERE zoom_level = 8
         UNION ALL
         -- etldoc: water_z9 ->  layer_water:z9
         SELECT *
         FROM water_z9
         WHERE zoom_level = 9
         UNION ALL
         -- etldoc: water_z10 ->  layer_water:z10
         SELECT *
         FROM water_z10
         WHERE zoom_level = 10
         UNION ALL
         -- etldoc: water_z11 ->  layer_water:z11
         SELECT *
         FROM water_z11
         WHERE zoom_level = 11
         UNION ALL
         -- etldoc: water_z12 ->  layer_water:z12
         SELECT *
         FROM water_z12
         WHERE zoom_level >= 12
     ) AS zoom_levels
WHERE geometry && bbox;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
