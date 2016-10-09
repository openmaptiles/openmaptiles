CREATE OR REPLACE FUNCTION ne_road_class(type VARCHAR) RETURNS VARCHAR AS $$
  SELECT CASE type
    WHEN 'Major Highway' THEN 'motorway'
    WHEN 'Secondary Highway' THEN 'trunk'
    WHEN 'Road' THEN 'primary'
    ELSE type
  END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE TABLE IF NOT EXISTS ne_10m_global_roads AS (
    SELECT geom, scalerank, ne_road_class(type) AS class
    FROM ne_10m_roads
    WHERE continent <> 'North America'
      AND featurecla = 'Road'
      AND type IN ('Major Highway', 'Secondary Highway', 'Road')
    UNION ALL
    SELECT geom, scalerank, ne_road_class(type) AS class
    FROM ne_10m_roads_north_america
    WHERE type IN ('Major Highway', 'Secondary Highway', 'Road')
);

CREATE INDEX IF NOT EXISTS ne_10m_global_roads_geom_idx ON ne_10m_global_roads USING gist(geom);
CREATE INDEX IF NOT EXISTS ne_10m_global_roads_scalerank_idx ON ne_10m_global_roads(scalerank);

CREATE OR REPLACE VIEW road_z4 AS (
    SELECT geom, class
    FROM ne_10m_global_roads
    WHERE scalerank <= 5
);

CREATE OR REPLACE VIEW road_z5 AS (
    SELECT geom, class
    FROM ne_10m_global_roads
    WHERE scalerank <= 6
);

CREATE OR REPLACE VIEW road_z6 AS (
    SELECT geom, class
    FROM ne_10m_global_roads
    WHERE scalerank <= 7
);

CREATE OR REPLACE VIEW road_z7 AS (
    SELECT geom, class
    FROM ne_10m_global_roads
    WHERE scalerank <= 7
);

CREATE TABLE IF NOT EXISTS road_z8 AS (
    SELECT ST_Simplify(way, 200) AS geom, class::text
    FROM roads
    WHERE class IN ('motorway','trunk')
);
CREATE INDEX IF NOT EXISTS road_z8_geom_idx ON road_z8 USING gist(geom);

CREATE TABLE IF NOT EXISTS road_z9 AS (
    SELECT ST_Simplify(way, 120) AS geom, class::text
    FROM roads
    WHERE class IN ('motorway','trunk', 'primary')
);
CREATE INDEX IF NOT EXISTS road_z9_geom_idx ON road_z9 USING gist(geom);

CREATE TABLE IF NOT EXISTS road_z10 AS (
    SELECT ST_Simplify(way, 50) AS geom, class::text
    FROM roads
    WHERE class IN ('motorway','trunk', 'primary', 'secondary')
);
CREATE INDEX IF NOT EXISTS road_z10_geom_idx ON road_z10 USING gist(geom);

CREATE TABLE IF NOT EXISTS road_z11 AS (
    SELECT ST_Simplify(way, 20) AS geom, class::text
    FROM roads
    WHERE class IN ('motorway','trunk', 'primary', 'secondary', 'tertiary')
);
CREATE INDEX IF NOT EXISTS road_z11_geom_idx ON road_z11 USING gist(geom);

CREATE OR REPLACE VIEW road_z12 AS (
    SELECT way AS geom, class::text
    FROM roads
    WHERE class IN ('motorway','trunk','primary', 'secondary', 'tertiary', 'minor')
    UNION ALL
    SELECT way AS geom, class::text
    FROM road_areas
);

CREATE OR REPLACE VIEW road_z13 AS (
    SELECT way AS geom, class::text
    FROM roads
    WHERE class NOT IN ('path')
    UNION ALL
    SELECT way AS geom, class::text
    FROM road_areas
);

CREATE OR REPLACE VIEW road_z14 AS (
    SELECT way AS geom, class::text
    FROM roads
    UNION ALL
    SELECT way AS geom, class::text
    FROM road_areas
);

CREATE OR REPLACE FUNCTION layer_road(bbox geometry, zoom_level int)
RETURNS TABLE(geom geometry, class text) AS $$
    SELECT geom, class::text FROM (
        SELECT * FROM road_z4 WHERE zoom_level BETWEEN 4 AND 5
        UNION ALL
        SELECT * FROM road_z5 WHERE zoom_level = 5
        UNION ALL
        SELECT * FROM road_z6 WHERE zoom_level = 6
        UNION ALL
        SELECT * FROM road_z7 WHERE zoom_level = 7
        UNION ALL
        SELECT * FROM road_z8 WHERE zoom_level = 8
        UNION ALL
        SELECT geom, class FROM road_z9 WHERE zoom_level = 9
        UNION ALL
        SELECT geom, class FROM road_z10 WHERE zoom_level = 10
        UNION ALL
        SELECT geom, class FROM road_z11 WHERE zoom_level = 11
        UNION ALL
        SELECT geom, class FROM road_z12 WHERE zoom_level = 12
        UNION ALL
        SELECT * FROM road_z13 WHERE zoom_level = 13
        UNION ALL
        SELECT * FROM road_z14 WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geom && bbox;
$$ LANGUAGE SQL IMMUTABLE;
