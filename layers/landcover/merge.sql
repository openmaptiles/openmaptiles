DROP TABLE IF EXISTS osm_landcover_gen_z0;
DROP TABLE IF EXISTS osm_landcover_gen_z1;
DROP TABLE IF EXISTS osm_landcover_gen_z2;
DROP TABLE IF EXISTS osm_landcover_gen_z3;
DROP TABLE IF EXISTS osm_landcover_gen_z4;
DROP TABLE IF EXISTS osm_landcover_gen_z5;
DROP TABLE IF EXISTS osm_landcover_gen_z6;
DROP TABLE IF EXISTS osm_landcover_gen_z7;
DROP TABLE IF EXISTS osm_landcover_gen_z8;
DROP TABLE IF EXISTS osm_landcover_gen_z9;
DROP TABLE IF EXISTS osm_landcover_gen_z10;
DROP TABLE IF EXISTS osm_landcover_gen_z11;
DROP TABLE IF EXISTS osm_landcover_gen_z12;
DROP TABLE IF EXISTS osm_landcover_gen_z13;
DROP TABLE IF EXISTS simplify_vw_z0 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z1 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z2 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z3 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z4 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z5 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z6 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z7 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z8 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z9 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z10 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z11 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z12 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z13 CASCADE;

-- etldoc: osm_landcover_polygon ->  simplify_vw_z13
CREATE TABLE simplify_vw_z13 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(13),2)),
             0.001))) AS geometry
    FROM osm_landcover_polygon
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(12),2)
);
CREATE INDEX ON simplify_vw_z13 USING GIST (geometry);

-- etldoc: simplify_vw_z13 ->  simplify_vw_z12
CREATE TABLE simplify_vw_z12 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(12),2)),
             0.001))) AS geometry
    FROM simplify_vw_z13
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(11),2)
);
CREATE INDEX ON simplify_vw_z12 USING GIST (geometry);

-- etldoc: simplify_vw_z12 ->  simplify_vw_z11
CREATE TABLE simplify_vw_z11 AS
(
    SELECT subclass,
            ST_MakeValid(
                ST_Union(
            ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(11),2)),
             0.001))) AS geometry
    FROM simplify_vw_z12
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(10),2)
);
CREATE INDEX ON simplify_vw_z11 USING GIST (geometry);