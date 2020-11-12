DROP TABLE IF EXISTS osm_landcover_gen_z7;
DROP TABLE IF EXISTS osm_landcover_gen_z8;
DROP TABLE IF EXISTS osm_landcover_gen_z9;
DROP TABLE IF EXISTS osm_landcover_gen_z10;
DROP TABLE IF EXISTS osm_landcover_gen_z11;
DROP TABLE IF EXISTS osm_landcover_gen_z12;
DROP TABLE IF EXISTS osm_landcover_gen_z13;

-- etldoc: osm_landcover_polygon ->  osm_landcover_gen_z7
CREATE TABLE osm_landcover_gen_z7 AS
(
    WITH simplify_vw_z7 AS
    (
        SELECT subclass,
               ST_MakeValid(
                ST_SimplifyVW(geometry, zres(7)*zres(7))) AS geometry
    FROM osm_landcover_polygon
	WHERE ST_Area(geometry) > power(zres(5),2)
	    )

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

-- etldoc: osm_landcover_polygon ->  osm_landcover_gen_z8
CREATE TABLE osm_landcover_gen_z8 AS
(
    WITH simplify_vw_z8 AS
    (
        SELECT subclass,
               ST_MakeValid(
                ST_SimplifyVW(geometry, zres(8)*zres(8))) AS geometry
    FROM osm_landcover_polygon
	WHERE ST_Area(geometry) > power(zres(6),2)
	    )

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
        ) union_geom
GROUP BY subclass,
         cid
    );

CREATE INDEX ON osm_landcover_gen_z8 USING GIST (geometry);

-- etldoc: osm_landcover_polygon ->  osm_landcover_gen_z9
CREATE TABLE osm_landcover_gen_z9 AS
(
    WITH simplify_vw_z9 AS
    (
        SELECT subclass,
               ST_MakeValid(
                ST_SimplifyVW(geometry, zres(9)*zres(9))) AS geometry
    FROM osm_landcover_polygon
	WHERE ST_Area(geometry) > power(zres(7),2)
	    )

SELECT subclass, 
       ST_MakeValid(
        (ST_dump(
         ST_Union(geometry))).geom) AS geometry
    FROM (
    	SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
    	FROM simplify_vw_z9
		WHERE ST_NPoints(geometry) < 50) union_geom50
	GROUP BY subclass,
             cid
	UNION ALL
	SELECT subclass, st_makevalid((ST_dump(ST_Union(geometry))).geom) AS geometry
    FROM (
    	SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
    	FROM simplify_vw_z9
		WHERE ST_NPoints(geometry) >= 50 AND ST_NPoints(geometry) < 300) union_geom300
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
		WHERE ST_NPoints(geometry) >= 300) union_geom_rest
	GROUP BY subclass,
             cid
    );

CREATE INDEX ON osm_landcover_gen_z9 USING GIST (geometry);

-- etldoc: osm_landcover_polygon ->  osm_landcover_gen_z10
CREATE TABLE osm_landcover_gen_z10 AS
(
    WITH simplify_vw_z10 AS
    (
        SELECT subclass,
               ST_MakeValid(
                ST_SimplifyVW(geometry, zres(10)*zres(10))) AS geometry
    FROM osm_landcover_polygon
	WHERE ST_Area(geometry) > power(zres(8),2)
	    )

SELECT subclass, 
       ST_MakeValid(
        (ST_dump(
         ST_Union(geometry))).geom) AS geometry
    FROM (
    	SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
    	FROM simplify_vw_z10
		WHERE ST_NPoints(geometry) < 50) union_geom50
	GROUP BY subclass,
             cid
	UNION ALL
	SELECT subclass, st_makevalid((ST_dump(ST_Union(geometry))).geom) AS geometry
    FROM (
    	SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
    	FROM simplify_vw_z10
		WHERE ST_NPoints(geometry) >= 50 AND ST_NPoints(geometry) < 300) union_geom300
	GROUP BY subclass,
             cid
	UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z10
    WHERE ST_NPoints(geometry) >= 300
    );

CREATE INDEX ON osm_landcover_gen_z10 USING GIST (geometry);

-- etldoc: osm_landcover_polygon ->  osm_landcover_gen_z11
CREATE TABLE osm_landcover_gen_z11 AS
(
    WITH simplify_vw_z11 AS
    (
        SELECT subclass,
               ST_MakeValid(
                ST_SimplifyVW(geometry, zres(11)*zres(11))) AS geometry
    FROM osm_landcover_polygon
	WHERE ST_Area(geometry) > power(zres(8),2)
	    )

SELECT subclass, 
       ST_MakeValid(
        (ST_dump(
         ST_Union(geometry))).geom) AS geometry
    FROM (
    	SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
    	FROM simplify_vw_z11
		WHERE ST_NPoints(geometry) < 50) union_geom50
	GROUP BY subclass,
             cid
	UNION ALL
	SELECT subclass, st_makevalid((ST_dump(ST_Union(geometry))).geom) AS geometry
    FROM (
    	SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
    	FROM simplify_vw_z11
		WHERE ST_NPoints(geometry) >= 50 AND ST_NPoints(geometry) < 300) union_geom300
	GROUP BY subclass,
             cid
	UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z11
    WHERE ST_NPoints(geometry) >= 300
    );

CREATE INDEX ON osm_landcover_gen_z11 USING GIST (geometry);

-- etldoc: osm_landcover_polygon ->  osm_landcover_gen_z12
CREATE TABLE osm_landcover_gen_z12 AS
(
    WITH simplify_vw_z12 AS
    (
        SELECT subclass,
               ST_MakeValid(
                ST_SimplifyVW(geometry, zres(12)*zres(12))) AS geometry
    FROM osm_landcover_polygon
	WHERE ST_Area(geometry) > power(zres(9),2)
	    )

SELECT subclass, 
       ST_MakeValid(
        (ST_dump(
         ST_Union(geometry))).geom) AS geometry
    FROM (
    	SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
    	FROM simplify_vw_z12
		WHERE ST_NPoints(geometry) < 50) union_geom50
	GROUP BY subclass,
             cid
	UNION ALL
	SELECT subclass, st_makevalid((ST_dump(ST_Union(geometry))).geom) AS geometry
    FROM (
    	SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
    	FROM simplify_vw_z12
		WHERE ST_NPoints(geometry) >= 50 AND ST_NPoints(geometry) < 300) union_geom300
	GROUP BY subclass,
             cid
	UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z12
    WHERE ST_NPoints(geometry) >= 300
    );

CREATE INDEX ON osm_landcover_gen_z12 USING GIST (geometry);

-- etldoc: osm_landcover_polygon ->  osm_landcover_gen_z13
CREATE TABLE osm_landcover_gen_z13 AS
(
    WITH simplify_vw_z13 AS
    (
        SELECT subclass,
               ST_MakeValid(
                ST_SimplifyVW(geometry, zres(13)*zres(13))) AS geometry
    FROM osm_landcover_polygon
	WHERE ST_Area(geometry) > power(zres(10),2)
	    )

SELECT subclass,
       ST_MakeValid(
        (ST_dump(
         ST_Union(geometry))).geom) AS geometry
    FROM (
    	SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
    	FROM simplify_vw_z13
		WHERE ST_NPoints(geometry) < 50) union_geom50
	GROUP BY subclass,
             cid
	UNION ALL
	SELECT subclass, st_makevalid((ST_dump(ST_Union(geometry))).geom) AS geometry
    FROM (
    	SELECT subclass,
               ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 1) over () AS cid, geometry
    	FROM simplify_vw_z13
		WHERE ST_NPoints(geometry) >= 50 AND ST_NPoints(geometry) < 300) union_geom300
	GROUP BY subclass,
             cid
	UNION ALL
    SELECT subclass,
           geometry
    FROM simplify_vw_z13
    WHERE ST_NPoints(geometry) >= 300
    );

CREATE INDEX ON osm_landcover_gen_z13 USING GIST (geometry);