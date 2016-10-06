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
    SELECT *
    FROM ne_10m_global_roads
    WHERE scalerank <= 5
);

CREATE OR REPLACE VIEW road_z5 AS (
    SELECT *
    FROM ne_10m_global_roads
    WHERE scalerank <= 6
);

CREATE OR REPLACE VIEW road_z6 AS (
    SELECT *
    FROM ne_10m_global_roads
    WHERE scalerank <= 7
);

CREATE OR REPLACE VIEW road_z7 AS (
    SELECT *
    FROM ne_10m_global_roads
    WHERE scalerank <= 7
);
