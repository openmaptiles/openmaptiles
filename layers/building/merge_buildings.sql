-- Merge building polygons together to have more large buildings at lower zoom levels

-- etldoc: osm_building_polygon ->  osm_merged_building_polygon
-- TODO: This is just a quick hack - needs to be improved
CREATE TABLE IF NOT EXISTS osm_building_merged_polygon_gen1 AS (
    SELECT * FROM (
    SELECT
        MAX(osm_id) AS osm_id,
        -- We first buffer the buildings so very close buildings get merged together
        -- TODO: Perhaps we can use snap to grid here?
        -- then we union the geometries to find out which geometries can be dissolved
        -- and unpack and simplify them.
        ST_Simplify((ST_Dump(ST_Union(ST_Buffer(geometry, 5)))).geom, 8) AS geometry
      FROM osm_building_polygon
      GROUP BY LabelGrid(geometry, 10000)
    ) AS grouped_buildings
    WHERE ST_Area(geometry) > 1000
);
CREATE INDEX IF NOT EXISTS osm_building_merged_polygon_geometry_idx ON osm_building_merged_polygon_gen1 USING gist(geometry);
