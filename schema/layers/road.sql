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
