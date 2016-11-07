

-- etldoc: ne_global_roads_sql [label="ne_global_roads.sql", shape=note ]
-- etldoc: function_ne_highway[label="FUNCTION ne_highway"]
-- etldoc: ne_global_roads_sql -> function_ne_highway
-- etldoc: function_ne_highway -> postgreSQL

CREATE OR REPLACE FUNCTION ne_highway(type VARCHAR) RETURNS VARCHAR AS $$
  SELECT CASE type
    WHEN 'Major Highway' THEN 'motorway'
    WHEN 'Secondary Highway' THEN 'trunk'
    WHEN 'Road' THEN 'primary'
    ELSE type
  END;
$$ LANGUAGE SQL IMMUTABLE;


-- etldoc: natural_earth [fillcolor=lightblue, style="rounded,filled", shape=box , label="Natural Earth" ];
-- etldoc: natural_earth -> ne_10m_roads 
-- etldoc: natural_earth -> ne_10m_roads_north_america

-- etldoc: ne_global_roads_sql -> ne_10m_global_roads  ;
CREATE TABLE IF NOT EXISTS ne_10m_global_roads AS (

    -- etldoc:  ne_10m_roads -> ne_10m_global_roads
    SELECT geom AS geometry, scalerank, ne_highway(type) AS highway
    FROM ne_10m_roads
    WHERE continent <> 'North America'
      AND featurecla = 'Road'
      AND type IN ('Major Highway', 'Secondary Highway', 'Road')
    UNION ALL

    -- etldoc: function_ne_highway -> ne_10m_global_roads  
    -- etldoc: ne_10m_roads_north_america ->  ne_10m_global_roads  
    SELECT geom AS geometry, scalerank, ne_highway(type) AS highway
    FROM ne_10m_roads_north_america
    WHERE type IN ('Major Highway', 'Secondary Highway', 'Road')
);

CREATE INDEX IF NOT EXISTS ne_10m_global_roads_geometry_idx ON ne_10m_global_roads USING gist(geometry);
CREATE INDEX IF NOT EXISTS ne_10m_global_roads_scalerank_idx ON ne_10m_global_roads(scalerank);
