-- Merge building polygons together to have more large buildings at lower zoom levels

-- etldoc: osm_building_polygon ->  osm_merged_building_polygon

-- Big help from Regina Obe http://lists.osgeo.org/pipermail/postgis-users/2007-October/017205.html for the ST_ExteriorRing fix and Nicklas Aven/Brad Koch http://gis.stackexchange.com/a/4508 for the fancy ST_Intersects

-- Perhaps combine all the create tables if possible?

-- Some temp tables, create a buffer for buildings of the distance to decide adjacent buildings and then take the exterior ring of that buffer
-- If you uncomment the part of the next line, you will only do adjacency tests on buildings that are smaller than 1000 to see if they have a nearby building.
CREATE TABLE IF NOT EXISTS buffer_table AS SELECT ST_Buffer(geometry,1) AS buffer FROM osm_building_polygon; -- WHERE ST_Area(geometry) < 1000;
CREATE TABLE IF NOT EXISTS extring_table AS SELECT ST_ExteriorRing(ST_GeometryN(buffer, generate_series(1, ST_NumGeometries(buffer)))) AS extring FROM buffer_table;
CREATE INDEX IF NOT EXISTS extring_line_idx ON extring_table USING gist(extring);

-- Find buildings that have a building adjacent within the buffer
-- If you uncomment the ST_Area limitation, you can ensure that the only nearby buildings that are considered for adjacency are ones smaller than 1000.
-- If you uncomment both this line and the other ST_Area limit, you will only be getting buildings that are < 1000 with adjacent buildings that are also < 1000
CREATE TABLE IF NOT EXISTS adjacent_buildings AS 
  SELECT DISTINCT geometry FROM osm_building_polygon AS building
  LEFT JOIN extring_table AS extring
  ON ST_Intersects(building.geometry,extring.extring)
  WHERE extring.extring IS NOT NULL; -- AND ST_Area(building.geometry) < 1000;

-- st_union the buildings that have adjacent buildings and dump to polygons
-- CREATE TABLE osm_building_union AS
--   SELECT (ST_Dump(ST_Union(geometry))).geom AS geometry
--   FROM adjacent_buildings;

-- Now, union all the big buildings with the adjacent buildings, st_union again and simplify.
CREATE TABLE osm_buildings_large AS
  SELECT ST_Simplify(geometry,4) AS geometry FROM 
  (SELECT (ST_Dump(ST_Union(geometry))).geom AS geometry FROM
  (SELECT (ST_Dump(ST_Union(geometry))).geom AS geometry
  FROM adjacent_buildings
  UNION ALL
  SELECT geometry
  FROM osm_building_polygon WHERE ST_Area(geometry) >= 1000)
  AS all_buildings) 
  AS union_buildings
  WHERE ST_Area(geometry) >= 1000;	-- Ensure the resulting area before simplify is greater than 1000

CREATE INDEX IF NOT EXISTS osm_buildings_large_geometry_idx ON osm_buildings_large USING gist(geometry);

-- DROP TABLE IF EXISTS osm_building_union;
DROP TABLE IF EXISTS adjacent_buildings;
DROP TABLE IF EXISTS extring_table;
DROP TABLE IF EXISTS buffer_table;



