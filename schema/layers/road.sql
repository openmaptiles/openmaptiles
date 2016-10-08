CREATE OR REPLACE FUNCTION ne_road_class(type VARCHAR) RETURNS VARCHAR AS $$
  SELECT CASE type
    WHEN 'Major Highway' THEN 'motorway'
    WHEN 'Secondary Highway' THEN 'trunk'
    WHEN 'Road' THEN 'primary'
    ELSE type
  END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE VIEW ne_10m_global_roads AS (
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

CREATE OR REPLACE VIEW road_z8 AS (
    SELECT way AS geom, class::text
    FROM roads
    WHERE class IN ('motorway','trunk')
);

CREATE OR REPLACE VIEW road_z9 AS (
    SELECT way AS geom, class::text
    FROM roads
    WHERE class IN ('motorway','trunk', 'primary')
);

CREATE OR REPLACE VIEW road_z10 AS (
    SELECT way AS geom, class::text
    FROM roads
    WHERE class IN ('motorway','trunk', 'primary', 'secondary')
);

CREATE OR REPLACE VIEW road_z11 AS (
    SELECT way AS geom, class::text
    FROM roads
    WHERE class IN ('motorway','trunk', 'primary', 'secondary', 'tertiary')
);

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
    WITH zoom_levels AS (
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
        SELECT ST_Simplify(geom, 200), class FROM road_z9 WHERE zoom_level = 9
        UNION ALL
        SELECT ST_Simplify(geom, 120), class FROM road_z10 WHERE zoom_level = 10
        UNION ALL
        SELECT ST_Simplify(geom, 50), class FROM road_z11 WHERE zoom_level = 11
        UNION ALL
        SELECT ST_Simplify(geom, 20), class FROM road_z12 WHERE zoom_level = 12
        UNION ALL
        SELECT * FROM road_z13 WHERE zoom_level = 13
        UNION ALL
        SELECT * FROM road_z14 WHERE zoom_level >= 14
    )
    SELECT geom, class::text FROM zoom_levels
    WHERE geom && bbox;
$$ LANGUAGE SQL IMMUTABLE;
