

CREATE OR REPLACE FUNCTION ne_highway(type VARCHAR) RETURNS VARCHAR AS $$
  SELECT CASE type
    WHEN 'Major Highway' THEN 'motorway'
    WHEN 'Secondary Highway' THEN 'trunk'
    WHEN 'Road' THEN 'primary'
    ELSE type
  END;
$$ LANGUAGE SQL IMMUTABLE;


-- etldoc: ne_global_roads_sql -> ne_10m_global_roads  ;
CREATE TABLE IF NOT EXISTS ne_10m_global_roads AS (

    -- etldoc:  ne_10m_roads -> ne_10m_global_roads
    SELECT geom AS geometry, scalerank, ne_highway(type) AS highway
    FROM ne_10m_roads
    WHERE continent <> 'North America'
      AND featurecla = 'Road'
      AND type IN ('Major Highway', 'Secondary Highway', 'Road')
    UNION ALL

    -- etldoc: ne_10m_roads_north_america ->  ne_10m_global_roads  
    SELECT geom AS geometry, scalerank, ne_highway(type) AS highway
    FROM ne_10m_roads_north_america
    WHERE type IN ('Major Highway', 'Secondary Highway', 'Road')
);

CREATE INDEX IF NOT EXISTS ne_10m_global_roads_geometry_idx ON ne_10m_global_roads USING gist(geometry);
CREATE INDEX IF NOT EXISTS ne_10m_global_roads_scalerank_idx ON ne_10m_global_roads(scalerank);
