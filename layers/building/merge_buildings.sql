-- Merge building polygons together to have more large buildings at lower zoom levels

-- etldoc: osm_building_polygon ->  osm_merged_building_polygon

-- Perhaps combine all the CREATE TABLEs if possible?

-- Get clusters
CREATE TABLE IF NOT EXISTS clusters AS SELECT * FROM (SELECT osm_id, ST_ClusterDBSCAN(geometry, eps := 1, minpoints := 2) OVER () AS cid FROM osm_building_polygon) AS clusters;
-- Join cluster ID onto buildings, even if cluster ID is null
CREATE TABLE IF NOT EXISTS building_clusters AS (SELECT clusters.cid,osm_building_polygon.geometry,osm_building_polygon.area,osm_building_polygon.height,osm_building_polygon.min_height,osm_building_polygon.levels,osm_building_polygon.min_level FROM clusters, osm_building_polygon WHERE clusters.osm_id = osm_building_polygon.osm_id);
-- ST_Union buildings in the same cluster, and select those greater than 1000
CREATE TABLE IF NOT EXISTS large_building_clusters AS (SELECT * FROM (SELECT ST_Union(geometry) AS geometry FROM building_clusters WHERE cid IS NOT NULL GROUP BY cid) AS stunion WHERE ST_Area(geometry) > 1000);

-- Union all the clusters of buildings that are large with the buildings that are isolated but large on their own
CREATE TABLE IF NOT EXISTS osm_buildings_large AS
  SELECT ST_Simplify(geometry,4) AS geometry FROM 
  (
    SELECT geometry
    FROM building_clusters		-- Add buildings with nothing adjacent but are larger than area already
    WHERE cid IS NULL AND area >= 1000	-- Not sure if area is accurate enough
      UNION ALL
    SELECT geometry
    FROM large_building_clusters	-- Already large enough
  )
  AS union_buildings;

-- Create our index on geometry
CREATE INDEX IF NOT EXISTS osm_buildings_large_geometry_idx ON osm_buildings_large USING gist(geometry);




