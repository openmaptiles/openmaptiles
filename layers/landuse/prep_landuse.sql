DROP TABLE IF EXISTS cluster_zres14;
CREATE TABLE cluster_zres14 AS 
(
WITH single_geom AS (
        SELECT (ST_Dump(geometry)).geom AS geometry
        FROM osm_landuse_polygon 
        WHERE landuse IN ('railway','dam','quarry','stadium','retail','cemetery', 'pitch', 'playground', 'track','theme_park','zoo')
    )
    SELECT ST_ClusterDBSCAN(geometry, eps := zres(14), minpoints := 1) over () AS cid,
           geometry
    FROM single_geom
);
CREATE INDEX ON cluster_zres14 USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres14_union;
CREATE TABLE cluster_zres14_union AS (
SELECT ST_Buffer(
            ST_Union(
                ST_Buffer(
                    ST_SnapToGrid(geometry, 0.01)
                    , zres(14), 'join=mitre'
                )
            ),-zres(14), 'join=mitre'
        ) AS geometry
FROM cluster_zres14
GROUP BY cid
);
CREATE INDEX ON cluster_zres14_union USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres12;
CREATE TABLE cluster_zres12 AS 
(
WITH single_geom AS (
    SELECT (ST_Dump(geometry)).geom AS geometry
    FROM osm_landuse_polygon 
    WHERE landuse IN ('railway','dam','quarry','stadium','retail','cemetery', 'pitch', 'playground', 'track','theme_park','zoo')
    )
    SELECT ST_ClusterDBSCAN(geometry, eps := zres(12), minpoints := 1) over () AS cid,
           geometry
    FROM single_geom
);
CREATE INDEX ON cluster_zres12 USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres12_union;
CREATE TABLE cluster_zres12_union AS 
(
SELECT ST_Buffer(
            ST_Union(
                ST_Buffer(
                    ST_SnapToGrid(geometry, 1)
                        , zres(12), 'join=mitre'
                    )
                ), -zres(12), 'join=mitre'
            ) AS geometry
FROM cluster_zres12
GROUP BY cid
);
CREATE INDEX ON cluster_zres12_union USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres9;
CREATE TABLE cluster_zres9 AS 
(
WITH single_geom AS (
        SELECT (ST_Dump(geometry)).geom AS geometry
        FROM osm_landuse_polygon 
        WHERE landuse IN ('railway','dam','quarry','stadium','retail','cemetery', 'pitch', 'playground', 'track','theme_park','zoo')
    )
    SELECT ST_ClusterDBSCAN(geometry, eps := zres(9), minpoints := 1) over () AS cid,
           geometry
    FROM single_geom
);
CREATE INDEX ON cluster_zres9 USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres9_union;
CREATE TABLE cluster_zres9_union AS 
(
SELECT ST_Buffer(
            ST_Union(
                ST_Buffer(
                    ST_SnapToGrid(geometry, 1)
                        , zres(9), 'join=mitre'
                    )
                ), -zres(9), 'join=mitre'
            ) AS geometry
FROM cluster_zres9
GROUP BY cid
);
CREATE INDEX ON cluster_zres9_union USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres4;
CREATE TABLE cluster_zres4 AS 
(
WITH single_geom AS (
        SELECT (ST_Dump(geometry)).geom AS geometry
        FROM osm_landuse_polygon 
        WHERE landuse IN ('railway','dam','quarry','stadium','retail','cemetery', 'pitch', 'playground', 'track','theme_park','zoo')
    )
    SELECT ST_ClusterDBSCAN(geometry, eps := zres(4), minpoints := 1) over () AS cid,
           geometry
    FROM single_geom
);
CREATE INDEX ON cluster_zres4 USING gist(geometry);


DROP TABLE IF EXISTS cluster_zres4_union;
CREATE TABLE cluster_zres4_union AS 
(
SELECT ST_Buffer(
            ST_Union(
                ST_Buffer(
                    ST_SnapToGrid(geometry, 1)
                        , zres(4), 'join=mitre'
                    )
                ), -zres(4), 'join=mitre'
            ) AS geometry
FROM cluster_zres4
GROUP BY cid
);
CREATE INDEX ON cluster_zres9_union USING gist(geometry);

-- For z4
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z4
DROP TABLE IF EXISTS osm_residential_gen_z4 CASCADE;
CREATE TABLE osm_residential_gen_z4 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(4), 2)) AS geometry
FROM cluster_zres9_union
WHERE ST_Area(geometry) > power(zres(4), 2) 
);
CREATE INDEX ON osm_residential_gen_z4 USING gist(geometry);

-- For z5
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z5
DROP TABLE IF EXISTS osm_residential_gen_z5 CASCADE;
CREATE TABLE osm_residential_gen_z5 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(5), 2)) AS geometry
FROM cluster_zres9_union
WHERE ST_Area(geometry) > power(zres(5), 2) 
);
CREATE INDEX ON osm_residential_gen_z5 USING gist(geometry);

-- For z6
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z6
DROP TABLE IF EXISTS osm_residential_gen_z6 CASCADE;
CREATE TABLE osm_residential_gen_z6 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(6), 2)) AS geometry
FROM cluster_zres9_union
WHERE ST_Area(geometry) > power(zres(6), 2) 
);
CREATE INDEX ON osm_residential_gen_z6 USING gist(geometry);


-- For z7
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z7
DROP TABLE IF EXISTS osm_residential_gen_z7 CASCADE;
CREATE TABLE osm_residential_gen_z7 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(7), 2)) AS geometry
FROM cluster_zres12_union
WHERE ST_Area(geometry) > power(zres(7), 2) 
);
CREATE INDEX ON osm_residential_gen_z7 USING gist(geometry);


-- For z8
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z8
DROP TABLE IF EXISTS osm_residential_gen_z8 CASCADE;
CREATE TABLE osm_residential_gen_z8 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(8), 2)) AS geometry
FROM cluster_zres12_union
WHERE ST_Area(geometry) > power(zres(8), 2) 
);
CREATE INDEX ON osm_residential_gen_z8 USING gist(geometry);


-- For z9
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z9
DROP TABLE IF EXISTS osm_residential_gen_z9 CASCADE;
CREATE TABLE osm_residential_gen_z9 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(9), 2)) AS geometry
FROM cluster_zres12_union
WHERE ST_Area(geometry) > power(zres(9), 2) 
);
CREATE INDEX ON osm_residential_gen_z9 USING gist(geometry);


-- For z10
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z10
DROP TABLE IF EXISTS osm_residential_gen_z10 CASCADE;
CREATE TABLE osm_residential_gen_z10 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(10), 2)) AS geometry
FROM cluster_zres14_union
WHERE ST_Area(geometry) > power(zres(10), 2) 
);
CREATE INDEX ON osm_residential_gen_z10 USING gist(geometry);


-- For z11
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z11
DROP TABLE IF EXISTS osm_residential_gen_z11 CASCADE;
CREATE TABLE osm_residential_gen_z11 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(11), 2)) AS geometry
FROM cluster_zres14_union
WHERE ST_Area(geometry) > power(zres(11), 2) 
);
CREATE INDEX ON osm_residential_gen_z11 USING gist(geometry);


-- For z12
-- etldoc: osm_landuse_polygon ->  osm_residential_gen_z12
DROP TABLE IF EXISTS osm_residential_gen_z12 CASCADE;
CREATE TABLE osm_residential_gen_z12 AS
(
SELECT ST_SimplifyVW(geometry, power(zres(12), 2)) AS geometry
FROM cluster_zres14_union
WHERE ST_Area(geometry) > power(zres(12), 2) 
);
CREATE INDEX ON osm_residential_gen_z12 USING gist(geometry);
