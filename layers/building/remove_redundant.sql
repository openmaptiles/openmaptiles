
-- DBScan to find buildings that are within 0m, including those that are within
CREATE TABLE IF NOT EXISTS clusters_touches AS
  SELECT * FROM
  (SELECT osm_id, ST_ClusterDBSCAN(geometry, eps := 0, minpoints := 2) OVER () AS cid
  FROM osm_building_polygon) AS clusters;

-- Inner join to get cid
CREATE TABLE IF NOT EXISTS building_clusters_touches AS
  (SELECT clusters_touches.cid, 
  osm_building_polygon.geometry,
  osm_building_polygon.osm_id,
  osm_building_polygon.area,
  osm_building_polygon.height,
  osm_building_polygon.min_height,
  osm_building_polygon.levels,
  osm_building_polygon.min_level FROM
  clusters_touches, osm_building_polygon
  WHERE clusters_touches.osm_id = osm_building_polygon.osm_id);

-- Build a list of redundant buildings where the child is within the parent, the cid is the same, the osm_id is not the same, 
-- and the height of the child is less than the parent and the min_height of the child is greater than the parent (it adds no value to the 3D representation).
-- This is like a 3D spatial within operation
CREATE TABLE redundant_buildings AS
  SELECT child.*,parent.geometry AS parent_geometry
  FROM building_clusters_touches child
    INNER JOIN building_clusters_touches parent ON
  ST_Within(child.geometry,parent.geometry) AND
  child.cid = parent.cid AND
  child.osm_id <> parent.osm_id AND
  greatest(COALESCE(child.height, child.levels*3.66,5)) <= greatest(COALESCE(parent.height, parent.levels*3.66,5)) AND
  greatest(0, COALESCE(child.min_height, child.min_level*3.66,0)) >= greatest(0, COALESCE(parent.min_height, parent.min_level*3.66,0));

-- Purge osm_building_polygon of these redundant buildings
DELETE FROM osm_building_polygon USING redundant_buildings WHERE osm_building_polygon.osm_id = redundant_buildings.osm_id;
