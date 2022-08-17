DROP TABLE IF EXISTS osm_landcover_gen_z7;
DROP TABLE IF EXISTS osm_landcover_gen_z8;
DROP TABLE IF EXISTS osm_landcover_gen_z9;
DROP TABLE IF EXISTS osm_landcover_gen_z10;
DROP TABLE IF EXISTS osm_landcover_gen_z11;
DROP TABLE IF EXISTS osm_landcover_gen_z12;
DROP TABLE IF EXISTS osm_landcover_gen_z13;
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
            ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(13),2)),
             0.001)) AS geometry
    FROM osm_landcover_polygon
    WHERE ST_Area(geometry) > power(zres(12),2)
);
CREATE INDEX ON simplify_vw_z13 USING GIST (geometry);

-- etldoc: simplify_vw_z13 ->  osm_landcover_gen_z13
CREATE TABLE osm_landcover_gen_z13 AS
(
    SELECT subclass, ST_MakeValid((ST_dump(ST_Union(geometry))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z13
        WHERE ST_NPoints(geometry) < 300
          AND subclass IN ('wood', 'forest')) union_geom300
    GROUP BY subclass,
             cid
    UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z13
    WHERE (ST_NPoints(geometry) >= 300 AND subclass IN ('wood', 'forest'))
       OR (subclass NOT IN ('wood', 'forest'))
    );

CREATE INDEX ON osm_landcover_gen_z13 USING GIST (geometry);


-- etldoc: simplify_vw_z13 ->  simplify_vw_z12
CREATE TABLE simplify_vw_z12 AS
(
    SELECT subclass,
           ST_MakeValid(
            ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(12),2)),
             0.001)) AS geometry
    FROM simplify_vw_z13
    WHERE ST_Area(geometry) > power(zres(11),2)
);
CREATE INDEX ON simplify_vw_z12 USING GIST (geometry);

-- etldoc: simplify_vw_z12 ->  osm_landcover_gen_z12
CREATE TABLE osm_landcover_gen_z12 AS
(
    SELECT subclass, ST_MakeValid((ST_dump(ST_Union(geometry))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z12
        WHERE ST_NPoints(geometry) < 300
          AND subclass IN ('wood', 'forest')) union_geom300
    GROUP BY subclass,
             cid
    UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z12
    WHERE (ST_NPoints(geometry) >= 300  AND subclass IN ('wood', 'forest'))
       OR (subclass NOT IN ('wood', 'forest'))
    );

CREATE INDEX ON osm_landcover_gen_z12 USING GIST (geometry);


-- etldoc: simplify_vw_z12 ->  simplify_vw_z11
CREATE TABLE simplify_vw_z11 AS
(
    SELECT subclass,
            ST_MakeValid(
            ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(11),2)),
             0.001)) AS geometry
    FROM simplify_vw_z12
    WHERE ST_Area(geometry) > power(zres(10),2)
);
CREATE INDEX ON simplify_vw_z11 USING GIST (geometry);

-- etldoc: simplify_vw_z11 ->  osm_landcover_gen_z11
CREATE TABLE osm_landcover_gen_z11 AS
(
    SELECT subclass, ST_MakeValid((ST_dump(ST_Union(geometry))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z11
        WHERE ST_NPoints(geometry) < 300
          AND subclass IN ('wood', 'forest')) union_geom300
    GROUP BY subclass,
             cid
    UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z11
    WHERE (ST_NPoints(geometry) >= 300 AND subclass IN ('wood', 'forest'))
       OR (subclass NOT IN ('wood', 'forest'))
    );

CREATE INDEX ON osm_landcover_gen_z11 USING GIST (geometry);


-- etldoc: simplify_vw_z11 ->  simplify_vw_z10
CREATE TABLE simplify_vw_z10 AS
(
    SELECT subclass,
           ST_MakeValid(
            ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(10),2)),
             0.001)) AS geometry
    FROM simplify_vw_z11
    WHERE ST_Area(geometry) > power(zres(9),2)
);
CREATE INDEX ON simplify_vw_z10 USING GIST (geometry);

-- etldoc: simplify_vw_z10 ->  osm_landcover_gen_z10
CREATE TABLE osm_landcover_gen_z10 AS
(
    SELECT subclass, ST_MakeValid((ST_dump(ST_Union(geometry))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z10
        WHERE ST_NPoints(geometry) < 300
          AND subclass IN ('wood', 'forest')) union_geom300
    GROUP BY subclass,
             cid
    UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z10
    WHERE (ST_NPoints(geometry) >= 300 AND subclass IN ('wood', 'forest'))
       OR (subclass NOT IN ('wood', 'forest'))
    );

CREATE INDEX ON osm_landcover_gen_z10 USING GIST (geometry);


-- etldoc: simplify_vw_z10 ->  simplify_vw_z9
CREATE TABLE simplify_vw_z9 AS
(
    SELECT subclass,
           ST_MakeValid(
            ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(9),2)),
             0.001)) AS geometry
    FROM simplify_vw_z10
    WHERE ST_Area(geometry) > power(zres(8),2)
);
CREATE INDEX ON simplify_vw_z9 USING GIST (geometry);

-- etldoc: simplify_vw_z9 ->  osm_landcover_gen_z9
CREATE TABLE osm_landcover_gen_z9 AS
(
    SELECT subclass, ST_MakeValid((ST_dump(ST_Union(geometry))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z9
        WHERE ST_NPoints(geometry) < 300
          AND subclass IN ('wood', 'forest')) union_geom300
    GROUP BY subclass,
             cid
    UNION ALL
    SELECT subclass,
           ST_MakeValid(
            (ST_Dump(
             ST_Union(geometry))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z9
        WHERE ST_NPoints(geometry) >= 300
          AND subclass IN ('wood', 'forest')) union_geom_rest
    GROUP BY subclass,
             cid
    UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z9
    WHERE subclass NOT IN ('wood', 'forest')
    );

CREATE INDEX ON osm_landcover_gen_z9 USING GIST (geometry);


-- etldoc: simplify_vw_z9 ->  simplify_vw_z8
CREATE TABLE simplify_vw_z8 AS
(
    SELECT subclass,
           ST_MakeValid(
            ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(8),2)),
             0.001)) AS geometry
    FROM simplify_vw_z9
    WHERE ST_Area(geometry) > power(zres(7),2)
    );
CREATE INDEX ON simplify_vw_z8 USING GIST (geometry);

-- etldoc: simplify_vw_z8 ->  osm_landcover_gen_z8
CREATE TABLE osm_landcover_gen_z8 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry))).geom) AS geometry
    FROM
        (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
               geometry
        FROM simplify_vw_z8
        WHERE subclass IN ('wood', 'forest')
        ) union_geom
    GROUP BY subclass,
             cid
    UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z8
    WHERE subclass NOT IN ('wood', 'forest')
    );

CREATE INDEX ON osm_landcover_gen_z8 USING GIST (geometry);


-- etldoc: simplify_vw_z8 ->  simplify_vw_z7
CREATE TABLE simplify_vw_z7 AS
(
    SELECT subclass,
           ST_MakeValid(
            ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(7),2)),
             0.001)) AS geometry
    FROM simplify_vw_z8
    WHERE ST_Area(geometry) > power(zres(6),2)
);
CREATE INDEX ON simplify_vw_z7 USING GIST (geometry);

-- etldoc: simplify_vw_z7 ->  osm_landcover_gen_z7
CREATE TABLE osm_landcover_gen_z7 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry))).geom) AS geometry
    FROM
        (
        SELECT  subclass,
                ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
                geometry
        FROM simplify_vw_z7
        ) union_geom
GROUP BY subclass,
         cid
    );

CREATE INDEX ON osm_landcover_gen_z7 USING GIST (geometry);

DROP TABLE IF EXISTS simplify_vw_z7 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z8 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z9 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z10 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z11 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z12 CASCADE;
DROP TABLE IF EXISTS simplify_vw_z13 CASCADE;
