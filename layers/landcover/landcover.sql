--TODO: Find a way to nicely generalize landcover
--CREATE TABLE IF NOT EXISTS landcover_grouped_gen2 AS (
--	SELECT osm_id, ST_Simplify((ST_Dump(geometry)).geom, 600) AS geometry, landuse, "natural", wetland
--	FROM (
--	  SELECT max(osm_id) AS osm_id, ST_Union(ST_Buffer(geometry, 600)) AS geometry, landuse, "natural", wetland
--	  FROM osm_landcover_polygon_gen1
--	  GROUP BY LabelGrid(geometry, 15000000), landuse, "natural", wetland
--	) AS grouped_measurements
--);
--CREATE INDEX IF NOT EXISTS landcover_grouped_gen2_geometry_idx ON landcover_grouped_gen2 USING gist(geometry);

CREATE OR REPLACE FUNCTION landcover_class(subclass varchar) RETURNS text AS
$$
SELECT CASE
           %%FIELD_MAPPING: class %%
           END;
$$ LANGUAGE SQL IMMUTABLE
                -- STRICT
                PARALLEL SAFE;

-- ne_50m_antarctic_ice_shelves_polys
-- etldoc: ne_50m_antarctic_ice_shelves_polys ->  ne_50m_antarctic_ice_shelves_polys_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_50m_antarctic_ice_shelves_polys_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_antarctic_ice_shelves_polys_gen_z4 AS
(
SELECT
    ST_Simplify(geometry, ZRes(6)) as geometry,
    'ice_shelf'::text AS subclass
FROM ne_50m_antarctic_ice_shelves_polys
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_antarctic_ice_shelves_polys_gen_z4_idx ON ne_50m_antarctic_ice_shelves_polys_gen_z4 USING gist (geometry);

-- ne_110m_glaciated_areas
-- etldoc: ne_110m_glaciated_areas ->  ne_110m_glaciated_areas_gen_z1
DROP MATERIALIZED VIEW IF EXISTS ne_110m_glaciated_areas_gen_z1 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_glaciated_areas_gen_z1 AS
(
SELECT
    ST_Simplify(geometry, ZRes(3)) as geometry,
    'glacier'::text AS subclass
FROM ne_110m_glaciated_areas
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_glaciated_areas_gen_z1_idx ON ne_110m_glaciated_areas_gen_z1 USING gist (geometry);

-- etldoc: ne_110m_glaciated_areas_gen_z1 ->  ne_110m_glaciated_areas_gen_z0
DROP MATERIALIZED VIEW IF EXISTS ne_110m_glaciated_areas_gen_z0 CASCADE;
CREATE MATERIALIZED VIEW ne_110m_glaciated_areas_gen_z0 AS
(
SELECT
    ST_Simplify(geometry, ZRes(2)) as geometry,
    subclass
FROM ne_110m_glaciated_areas_gen_z1
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_110m_glaciated_areas_gen_z0_idx ON ne_110m_glaciated_areas_gen_z0 USING gist (geometry);

-- etldoc: ne_50m_antarctic_ice_shelves_polys_gen_z4 ->  ne_50m_antarctic_ice_shelves_polys_gen_z3
DROP MATERIALIZED VIEW IF EXISTS ne_50m_antarctic_ice_shelves_polys_gen_z3 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_antarctic_ice_shelves_polys_gen_z3 AS
(
SELECT
    ST_Simplify(geometry, ZRes(5)) as geometry,
    subclass
FROM ne_50m_antarctic_ice_shelves_polys_gen_z4
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_antarctic_ice_shelves_polys_gen_z3_idx ON ne_50m_antarctic_ice_shelves_polys_gen_z3 USING gist (geometry);

-- etldoc: ne_50m_antarctic_ice_shelves_polys_gen_z3 ->  ne_50m_antarctic_ice_shelves_polys_gen_z2
DROP MATERIALIZED VIEW IF EXISTS ne_50m_antarctic_ice_shelves_polys_gen_z2 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_antarctic_ice_shelves_polys_gen_z2 AS
(
SELECT
    ST_Simplify(geometry, ZRes(4)) as geometry,
    subclass
FROM ne_50m_antarctic_ice_shelves_polys_gen_z3
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_antarctic_ice_shelves_polys_gen_z2_idx ON ne_50m_antarctic_ice_shelves_polys_gen_z2 USING gist (geometry);

-- ne_50m_glaciated_areas
-- etldoc: ne_50m_glaciated_areas ->  ne_50m_glaciated_areas_gen_z4
DROP MATERIALIZED VIEW IF EXISTS ne_50m_glaciated_areas_gen_z4 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_glaciated_areas_gen_z4 AS
(
SELECT
    ST_Simplify(geometry, ZRes(6)) as geometry,
    'glacier'::text AS subclass
FROM ne_50m_glaciated_areas
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_glaciated_areas_gen_z4_idx ON ne_50m_glaciated_areas_gen_z4 USING gist (geometry);

-- etldoc: ne_50m_glaciated_areas_gen_z4 ->  ne_50m_glaciated_areas_gen_z3
DROP MATERIALIZED VIEW IF EXISTS ne_50m_glaciated_areas_gen_z3 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_glaciated_areas_gen_z3 AS
(
SELECT
    ST_Simplify(geometry, ZRes(5)) as geometry,
    subclass
FROM ne_50m_glaciated_areas_gen_z4
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_glaciated_areas_gen_z3_idx ON ne_50m_glaciated_areas_gen_z3 USING gist (geometry);

-- etldoc: ne_50m_glaciated_areas_gen_z3 ->  ne_50m_glaciated_areas_gen_z2
DROP MATERIALIZED VIEW IF EXISTS ne_50m_glaciated_areas_gen_z2 CASCADE;
CREATE MATERIALIZED VIEW ne_50m_glaciated_areas_gen_z2 AS
(
SELECT
    ST_Simplify(geometry, ZRes(4)) as geometry,
    subclass
FROM ne_50m_glaciated_areas_gen_z3
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_50m_glaciated_areas_gen_z2_idx ON ne_50m_glaciated_areas_gen_z2 USING gist (geometry);

-- ne_10m_glaciated_areas
-- etldoc: ne_10m_glaciated_areas ->  ne_10m_glaciated_areas_gen_z6
DROP MATERIALIZED VIEW IF EXISTS ne_10m_glaciated_areas_gen_z6 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_glaciated_areas_gen_z6 AS
(
SELECT
    ST_Simplify(geometry, ZRes(8)) as geometry,
    'glacier'::text AS subclass
FROM ne_10m_glaciated_areas
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_glaciated_areas_gen_z6_idx ON ne_10m_glaciated_areas_gen_z6 USING gist (geometry);

-- etldoc: ne_10m_glaciated_areas_gen_z6 ->  ne_10m_glaciated_areas_gen_z5
DROP MATERIALIZED VIEW IF EXISTS ne_10m_glaciated_areas_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_glaciated_areas_gen_z5 AS
(
SELECT
    ST_Simplify(geometry, ZRes(7)) as geometry,
    subclass
FROM ne_10m_glaciated_areas_gen_z6
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_glaciated_areas_gen_z5_idx ON ne_10m_glaciated_areas_gen_z5 USING gist (geometry);

-- ne_10m_antarctic_ice_shelves_polys
-- etldoc: ne_10m_antarctic_ice_shelves_polys ->  ne_10m_antarctic_ice_shelves_polys_gen_z6
DROP MATERIALIZED VIEW IF EXISTS ne_10m_antarctic_ice_shelves_polys_gen_z6 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_antarctic_ice_shelves_polys_gen_z6 AS
(
SELECT
    ST_Simplify(geometry, ZRes(8)) as geometry,
    'ice_shelf'::text AS subclass
FROM ne_10m_antarctic_ice_shelves_polys
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_antarctic_ice_shelves_polys_gen_z6_idx ON ne_10m_antarctic_ice_shelves_polys_gen_z6 USING gist (geometry);

-- etldoc: ne_10m_antarctic_ice_shelves_polys_gen_z6 ->  ne_10m_antarctic_ice_shelves_polys_gen_z5
DROP MATERIALIZED VIEW IF EXISTS ne_10m_antarctic_ice_shelves_polys_gen_z5 CASCADE;
CREATE MATERIALIZED VIEW ne_10m_antarctic_ice_shelves_polys_gen_z5 AS
(
SELECT
    ST_Simplify(geometry, ZRes(7)) as geometry,
    subclass
FROM ne_10m_antarctic_ice_shelves_polys_gen_z6
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS ne_10m_antarctic_ice_shelves_polys_gen_z5_idx ON ne_10m_antarctic_ice_shelves_polys_gen_z5 USING gist (geometry);

-- etldoc: ne_110m_glaciated_areas_gen_z0 ->  landcover_z0
CREATE OR REPLACE VIEW landcover_z0 AS
(
SELECT
    geometry,
    subclass
FROM ne_110m_glaciated_areas_gen_z0
    );

-- etldoc: ne_110m_glaciated_areas_gen_z1 ->  landcover_z1
CREATE OR REPLACE VIEW landcover_z1 AS
(
SELECT
    geometry,
    subclass
FROM ne_110m_glaciated_areas_gen_z1
    );

CREATE OR REPLACE VIEW landcover_z2 AS
(
-- etldoc: ne_50m_glaciated_areas_gen_z2 ->  landcover_z2
SELECT
    geometry,
    subclass
FROM ne_50m_glaciated_areas_gen_z2
UNION ALL
-- etldoc: ne_50m_antarctic_ice_shelves_polys_gen_z2 ->  landcover_z2
SELECT
    geometry,
    subclass
FROM ne_50m_antarctic_ice_shelves_polys_gen_z2
    );

CREATE OR REPLACE VIEW landcover_z3 AS
(
-- etldoc: ne_50m_glaciated_areas_gen_z3 ->  landcover_z3
SELECT
    geometry,
    subclass
FROM ne_50m_glaciated_areas_gen_z3
UNION ALL
-- etldoc: ne_50m_antarctic_ice_shelves_polys_gen_z3 ->  landcover_z3
SELECT
    geometry,
    subclass
FROM ne_50m_antarctic_ice_shelves_polys_gen_z3
    );

CREATE OR REPLACE VIEW landcover_z4 AS
(
-- etldoc: ne_50m_glaciated_areas_gen_z4 ->  landcover_z4
SELECT
    geometry,
    subclass
FROM ne_50m_glaciated_areas_gen_z4
UNION ALL
-- etldoc: ne_50m_antarctic_ice_shelves_polys_gen_z4 ->  landcover_z4
SELECT
    geometry,
    subclass
FROM ne_50m_antarctic_ice_shelves_polys_gen_z4
    );

CREATE OR REPLACE VIEW landcover_z5 AS
(
-- etldoc: ne_10m_glaciated_areas_gen_z5 ->  landcover_z5
SELECT
    geometry,
    subclass
FROM ne_10m_glaciated_areas_gen_z5
UNION ALL
-- etldoc: ne_10m_antarctic_ice_shelves_polys_gen_z5 ->  landcover_z5
SELECT
    geometry,
    subclass
FROM ne_10m_antarctic_ice_shelves_polys_gen_z5
    );

CREATE OR REPLACE VIEW landcover_z6 AS
(
-- etldoc: ne_10m_glaciated_areas_gen_z6 ->  landcover_z6
SELECT
    geometry,
    subclass
FROM ne_10m_glaciated_areas_gen_z6
UNION ALL
-- etldoc: ne_10m_antarctic_ice_shelves_polys_gen_z6 ->  landcover_z6
SELECT
    geometry,
    subclass
FROM ne_10m_antarctic_ice_shelves_polys_gen_z6
    );

-- etldoc: layer_landcover[shape=record fillcolor=lightpink, style="rounded, filled", label="layer_landcover | <z0> z0 | <z1> z1 | <z2> z2 | <z3> z3 | <z4> z4 | <z5> z5 | <z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_landcover(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                geometry geometry,
                class    text,
                subclass text
            )
AS
$$
SELECT geometry,
       landcover_class(subclass) AS class,
       subclass
FROM (
         -- etldoc:  landcover_z0 -> layer_landcover:z0
         SELECT geometry, 
                subclass
         FROM landcover_z0
         WHERE zoom_level = 0
           AND geometry && bbox
         UNION ALL
         -- etldoc:  landcover_z1 -> layer_landcover:z1
         SELECT geometry,
                subclass
         FROM landcover_z1
         WHERE zoom_level = 1
           AND geometry && bbox
         UNION ALL
         -- etldoc:  landcover_z2 -> layer_landcover:z2
         SELECT geometry, 
                subclass
         FROM landcover_z2
         WHERE zoom_level = 2
           AND geometry && bbox
         UNION ALL
         -- etldoc:  landcover_z3 -> layer_landcover:z3
         SELECT geometry,
                subclass
         FROM landcover_z3
         WHERE zoom_level = 3
           AND geometry && bbox
         UNION ALL
         -- etldoc:  landcover_z4 -> layer_landcover:z4
         SELECT geometry,
                subclass
         FROM landcover_z4
         WHERE zoom_level = 4
           AND geometry && bbox
         UNION ALL
         -- etldoc:  landcover_z5 -> layer_landcover:z5
         SELECT geometry, 
                subclass
         FROM landcover_z5
         WHERE zoom_level = 5
           AND geometry && bbox
         UNION ALL
         -- etldoc:  landcover_z6 -> layer_landcover:z6
         SELECT geometry,
                subclass
         FROM landcover_z6
         WHERE zoom_level = 6
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z7 -> layer_landcover:z7
         SELECT geometry, 
                subclass
         FROM osm_landcover_gen_z7
         WHERE zoom_level = 7
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z8 -> layer_landcover:z8
         SELECT geometry, 
                subclass
         FROM osm_landcover_gen_z8
         WHERE zoom_level = 8
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z9 -> layer_landcover:z9
         SELECT geometry, 
                subclass
         FROM osm_landcover_gen_z9
         WHERE zoom_level = 9
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z10 -> layer_landcover:z10
         SELECT geometry, 
                subclass
         FROM osm_landcover_gen_z10
         WHERE zoom_level = 10
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z11 -> layer_landcover:z11
         SELECT geometry, 
                subclass
         FROM osm_landcover_gen_z11
         WHERE zoom_level = 11
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z12 -> layer_landcover:z12
         SELECT geometry, 
                subclass
         FROM osm_landcover_gen_z12
         WHERE zoom_level = 12
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z13 -> layer_landcover:z13
         SELECT geometry, 
                subclass
         FROM osm_landcover_gen_z13
         WHERE zoom_level = 13
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_polygon -> layer_landcover:z14_
         SELECT geometry, 
                subclass
         FROM osm_landcover_polygon
         WHERE zoom_level >= 14
           AND geometry && bbox
     ) AS zoom_levels;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;