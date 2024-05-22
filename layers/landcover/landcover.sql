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
         -- etldoc:  osm_landcover_gen_z0 -> layer_landcover:z0
         SELECT geometry, 
                subclass
         FROM osm_landcover_gen_z0
         WHERE zoom_level = 0
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z1 -> layer_landcover:z1
         SELECT geometry,
                subclass
         FROM osm_landcover_gen_z1
         WHERE zoom_level = 1
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z2 -> layer_landcover:z2
         SELECT geometry, 
                subclass
         FROM osm_landcover_gen_z2
         WHERE zoom_level = 2
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z3 -> layer_landcover:z3
         SELECT geometry,
                subclass
         FROM osm_landcover_gen_z3
         WHERE zoom_level = 3
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z4 -> layer_landcover:z4
         SELECT geometry,
                subclass
         FROM osm_landcover_gen_z4
         WHERE zoom_level = 4
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z5 -> layer_landcover:z5
         SELECT geometry, 
                subclass
         FROM osm_landcover_gen_z5
         WHERE zoom_level = 5
           AND geometry && bbox
         UNION ALL
         -- etldoc:  osm_landcover_gen_z6 -> layer_landcover:z6
         SELECT geometry,
                subclass
         FROM osm_landcover_gen_z6
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
         --UNION ALL
         ---- etldoc:  osm_landcover_gen_z13 -> layer_landcover:z13
         --SELECT geometry, 
         --       subclass
         --FROM osm_landcover_gen_z13
         --WHERE zoom_level = 13
         --  AND geometry && bbox
         --UNION ALL
         ---- etldoc:  osm_landcover_polygon -> layer_landcover:z14_
         --SELECT geometry, 
         --       subclass
         --FROM osm_landcover_polygon
         --WHERE zoom_level >= 14
         --  AND geometry && bbox
     ) AS zoom_levels;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;