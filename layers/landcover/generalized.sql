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

PRINT "This message is unique"
-- etldoc: simplify_vw_z13 ->  osm_landcover_gen_z13
CREATE TABLE osm_landcover_gen_z13 AS
(
    SELECT subclass, ST_MakeValid((ST_dump(ST_Union(geometry,0.001))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z13
        WHERE ST_NPoints(geometry) < 300) union_geom300a
    GROUP BY subclass,
             cid
    );
CREATE INDEX ON osm_landcover_gen_z13 USING GIST (geometry);



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

-- etldoc: simplify_vw_z12 ->  osm_landcover_gen_z12
CREATE TABLE osm_landcover_gen_z12 AS
(
    SELECT subclass, ST_MakeValid((ST_dump(ST_Union(geometry,0.001))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z12
        WHERE ST_NPoints(geometry) < 300)) union_geom300b
    GROUP BY subclass,
             cid
    UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z12
    WHERE (ST_NPoints(geometry) >= 300 )
    );

CREATE INDEX ON osm_landcover_gen_z12 USING GIST (geometry);



-- etldoc: simplify_vw_z12 ->  simplify_vw_z11
CREATE TABLE simplify_vw_z11 AS
(
    SELECT subclass,
            ST_MakeValid(
            ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(11),2)),
             0.001))) AS geometry
    FROM simplify_vw_z12
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(10),2)
);
CREATE INDEX ON simplify_vw_z11 USING GIST (geometry);

-- etldoc: simplify_vw_z11 ->  osm_landcover_gen_z11
CREATE TABLE osm_landcover_gen_z11 AS
(
    SELECT subclass, ST_MakeValid((ST_dump(ST_Union(geometry,0.001))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z11
        WHERE ST_NPoints(geometry) < 300) union_geom300c
    GROUP BY subclass,
             cid
    );

CREATE INDEX ON osm_landcover_gen_z11 USING GIST (geometry);



-- etldoc: simplify_vw_z11 ->  simplify_vw_z10
CREATE TABLE simplify_vw_z10 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(10),2)),
             0.001))) AS geometry
    FROM simplify_vw_z11
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(9),2)
);
CREATE INDEX ON simplify_vw_z10 USING GIST (geometry);

-- etldoc: simplify_vw_z10 ->  osm_landcover_gen_z10
CREATE TABLE osm_landcover_gen_z10 AS
(
    SELECT subclass, ST_MakeValid((ST_dump(ST_Union(geometry,0.001))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z10
        WHERE ST_NPoints(geometry) < 300) union_geom300d
    GROUP BY subclass,
             cid
    UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z10
    WHERE (ST_NPoints(geometry) >= 300);

CREATE INDEX ON osm_landcover_gen_z10 USING GIST (geometry);



-- etldoc: simplify_vw_z10 ->  simplify_vw_z9
CREATE TABLE simplify_vw_z9 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(9),2)),
             0.001))) AS geometry
    FROM simplify_vw_z10
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(8),2)
);
CREATE INDEX ON simplify_vw_z9 USING GIST (geometry);

-- etldoc: simplify_vw_z9 ->  osm_landcover_gen_z9
CREATE TABLE osm_landcover_gen_z9 AS
(
    SELECT subclass, ST_MakeValid((ST_dump(ST_Union(geometry,0.001))).geom) AS geometry
    FROM (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
        FROM simplify_vw_z9
        WHERE ST_NPoints(geometry) < 300 union_geom300e
    GROUP BY subclass,
             cid
    );

CREATE INDEX ON osm_landcover_gen_z9 USING GIST (geometry);



-- etldoc: simplify_vw_z9 ->  simplify_vw_z8
CREATE TABLE simplify_vw_z8 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(8),2)),
             0.001))) AS geometry
    FROM simplify_vw_z9
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(7),2)
    );
CREATE INDEX ON simplify_vw_z8 USING GIST (geometry);

-- etldoc: simplify_vw_z8 ->  osm_landcover_gen_z8
CREATE TABLE osm_landcover_gen_z8 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry,0.001))).geom) AS geometry
    FROM
        (
        SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
               geometry
        FROM simplify_vw_z8
        ) union_geom
    GROUP BY subclass,
             cid
    );

CREATE INDEX ON osm_landcover_gen_z8 USING GIST (geometry);



-- etldoc: simplify_vw_z8 ->  simplify_vw_z7
CREATE TABLE simplify_vw_z7 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(7),2)),
             0.001))) AS geometry
    FROM simplify_vw_z8
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(6),2)
);
CREATE INDEX ON simplify_vw_z7 USING GIST (geometry);

-- etldoc: simplify_vw_z7 ->  osm_landcover_gen_z7
CREATE TABLE osm_landcover_gen_z7 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry,0.001))).geom) AS geometry
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



-- etldoc: simplify_vw_z7 ->  simplify_vw_z6
CREATE TABLE simplify_vw_z6 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(6),2)),
             0.001))) AS geometry
    FROM simplify_vw_z7
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(5),2)
);
CREATE INDEX ON simplify_vw_z6 USING GIST (geometry);

-- etldoc: simplify_vw_z6 ->  osm_landcover_gen_z6
CREATE TABLE osm_landcover_gen_z6 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry,0.001))).geom) AS geometry
    FROM
        (
        SELECT  subclass,
                ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
                geometry
        FROM simplify_vw_z6
        ) union_geom
GROUP BY subclass,
         cid
    );

CREATE INDEX ON osm_landcover_gen_z6 USING GIST (geometry);



-- etldoc: simplify_vw_z6 ->  simplify_vw_z5
CREATE TABLE simplify_vw_z5 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(5),2)),
             0.001))) AS geometry
    FROM simplify_vw_z6
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(4),2)
);
CREATE INDEX ON simplify_vw_z6 USING GIST (geometry);

-- etldoc: simplify_vw_z5 ->  osm_landcover_gen_z5
CREATE TABLE osm_landcover_gen_z5 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry,0.001))).geom) AS geometry
    FROM
        (
        SELECT  subclass,
                ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
                geometry
        FROM simplify_vw_z5
        ) union_geom
GROUP BY subclass,
         cid
    );

CREATE INDEX ON osm_landcover_gen_z5 USING GIST (geometry);



-- etldoc: simplify_vw_z5 ->  simplify_vw_z4
CREATE TABLE simplify_vw_z4 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(4),2)),
             0.001))) AS geometry
    FROM simplify_vw_z5
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(3),2)
);
CREATE INDEX ON simplify_vw_z4 USING GIST (geometry);

-- etldoc: simplify_vw_z4 ->  osm_landcover_gen_z4
CREATE TABLE osm_landcover_gen_z4 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry,0.001))).geom) AS geometry
    FROM
        (
        SELECT  subclass,
                ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
                geometry
        FROM simplify_vw_z4
        ) union_geom
GROUP BY subclass,
         cid
    );

CREATE INDEX ON osm_landcover_gen_z4 USING GIST (geometry);



-- etldoc: simplify_vw_z4 ->  simplify_vw_z3
CREATE TABLE simplify_vw_z3 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(3),2)),
             0.001))) AS geometry
    FROM simplify_vw_z4
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(2),2)
);
CREATE INDEX ON simplify_vw_z3 USING GIST (geometry);

-- etldoc: simplify_vw_z3 ->  osm_landcover_gen_z3
CREATE TABLE osm_landcover_gen_z3 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry,0.001))).geom) AS geometry
    FROM
        (
        SELECT  subclass,
                ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
                geometry
        FROM simplify_vw_z3
        ) union_geom
GROUP BY subclass,
         cid
    );

CREATE INDEX ON osm_landcover_gen_z3 USING GIST (geometry);



-- etldoc: simplify_vw_z4 ->  simplify_vw_z3
CREATE TABLE simplify_vw_z3 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(3),2)),
             0.001))) AS geometry
    FROM simplify_vw_z4
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(2),2)
);
CREATE INDEX ON simplify_vw_z3 USING GIST (geometry);

-- etldoc: simplify_vw_z3 ->  osm_landcover_gen_z3
CREATE TABLE osm_landcover_gen_z3 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry,0.001))).geom) AS geometry
    FROM
        (
        SELECT  subclass,
                ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
                geometry
        FROM simplify_vw_z3
        ) union_geom
GROUP BY subclass,
         cid
    );

CREATE INDEX ON osm_landcover_gen_z3 USING GIST (geometry);



-- etldoc: simplify_vw_z3 ->  simplify_vw_z2
CREATE TABLE simplify_vw_z2 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(2),2)),
             0.001))) AS geometry
    FROM simplify_vw_z3
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(1),2)
);
CREATE INDEX ON simplify_vw_z2 USING GIST (geometry);

-- etldoc: simplify_vw_z2 ->  osm_landcover_gen_z2
CREATE TABLE osm_landcover_gen_z2 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry,0.001))).geom) AS geometry
    FROM
        (
        SELECT  subclass,
                ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
                geometry
        FROM simplify_vw_z2
        ) union_geom
GROUP BY subclass,
         cid
    );

CREATE INDEX ON osm_landcover_gen_z2 USING GIST (geometry);



-- etldoc: simplify_vw_z2 ->  simplify_vw_z1
CREATE TABLE simplify_vw_z1 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(1),2)),
             0.001))) AS geometry
    FROM simplify_vw_z2
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(0),2)
);
CREATE INDEX ON simplify_vw_z1 USING GIST (geometry);

-- etldoc: simplify_vw_z1 ->  osm_landcover_gen_z1
CREATE TABLE osm_landcover_gen_z1 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry,0.001))).geom) AS geometry
    FROM
        (
        SELECT  subclass,
                ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
                geometry
        FROM simplify_vw_z1
        ) union_geom
GROUP BY subclass,
         cid
    );

CREATE INDEX ON osm_landcover_gen_z1 USING GIST (geometry);



-- etldoc: simplify_vw_z1 ->  simplify_vw_z0
CREATE TABLE simplify_vw_z0 AS
(
    SELECT subclass,
           ST_MakeValid(
             ST_Union(
               ST_SnapToGrid(
             ST_SimplifyVW(geometry, power(zres(0),2)),
             0.001))) AS geometry
    FROM simplify_vw_z1
    GROUP BY subclass
    WHERE ST_Area(geometry) > power(zres(0),2)
);
CREATE INDEX ON simplify_vw_z0 USING GIST (geometry);

-- etldoc: simplify_vw_z1 ->  osm_landcover_gen_z1
CREATE TABLE osm_landcover_gen_z0 AS
(
SELECT subclass,
       ST_MakeValid(
        (ST_Dump(
         ST_Union(geometry,0.001))).geom) AS geometry
    FROM
        (
        SELECT  subclass,
                ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) OVER () AS cid,
                geometry
        FROM simplify_vw_z0
        ) union_geom
GROUP BY subclass,
         cid
    );

CREATE INDEX ON osm_landcover_gen_z0 USING GIST (geometry);


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
