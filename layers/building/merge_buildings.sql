-- etldoc: osm_building_polygon ->  osm_merged_building_polygon

-- Merge building polygons together to have more large buildings at lower zoom levels

-- ST_Union buildings in the same cluster, and select those greater than 1000
CREATE TABLE IF NOT EXISTS large_building_clusters AS
  (
    SELECT * FROM
      (
         SELECT ST_Union(geometry) AS 
         geometry FROM building_clusters_touches
         WHERE cid IS NOT NULL GROUP BY cid
      ) AS stunion
      WHERE ST_Area(geometry) > 1000
  );

-- Union all the clusters of buildings that are large with the buildings that are isolated but large on their own
CREATE TABLE IF NOT EXISTS osm_buildings_large AS
  SELECT ST_Simplify(geometry,4) AS geometry FROM 
  (
    SELECT geometry
    FROM building_clusters_touches		-- Add buildings with nothing adjacent but are larger than area already
    WHERE cid IS NULL AND area >= 1000	-- Not sure if area is accurate enough
      UNION ALL
    SELECT geometry
    FROM large_building_clusters	-- Already large enough
  )
  AS union_buildings;

-- Create our index on geometry
CREATE INDEX IF NOT EXISTS osm_buildings_large_geometry_idx ON osm_buildings_large USING gist(geometry);




