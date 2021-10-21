UPDATE osm_park_polygon_geometry
   SET geom_z13 = ST_Simplify(geometry, ZRes(12))
 WHERE area>power(ZRes(12),2);

UPDATE osm_park_polygon_geometry
   SET geom_z12 = ST_Simplify(geom_z13, ZRes(11))
 WHERE geom_z13 IS NOT NULL;

UPDATE osm_park_polygon_geometry
   SET geom_z11 = ST_Simplify(geom_z12, ZRes(10))
 WHERE geom_z12 IS NOT NULL;

UPDATE osm_park_polygon_geometry
   SET geom_z10 = ST_Simplify(geom_z11, ZRes(9))
 WHERE geom_z11 IS NOT NULL;

UPDATE osm_park_polygon_geometry
   SET geom_z9 = ST_Simplify(geom_z10, ZRes(8))
 WHERE geom_z10 IS NOT NULL;

UPDATE osm_park_polygon_geometry
   SET geom_z8 = ST_Simplify(geom_z9, ZRes(7))
 WHERE geom_z9 IS NOT NULL;

UPDATE osm_park_polygon_geometry
   SET geom_z7 = ST_Simplify(geom_z8, ZRes(6))
 WHERE geom_z8 IS NOT NULL;

UPDATE osm_park_polygon_geometry
   SET geom_z6 = ST_Simplify(geom_z7, ZRes(5))
 WHERE geom_z7 IS NOT NULL;

UPDATE osm_park_polygon_geometry
   SET geom_z5 = ST_Simplify(geom_z6, ZRes(4))
 WHERE geom_z6 IS NOT NULL;

DROP MATERIALIZED VIEW IF EXISTS osm_park_polygon_dissolve_z4 CASCADE;
CREATE MATERIALIZED VIEW osm_park_polygon_dissolve_z4 AS
(
  SELECT
         (ST_Dump(
            ST_Union(
              ST_MakeValid(geom_z5)))).geom AS geometry
  FROM osm_park_polygon_geometry
);
