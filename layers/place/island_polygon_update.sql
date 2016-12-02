-- etldoc:  osm_island_polygon ->  osm_island_polygon
UPDATE osm_island_polygon  SET geometry=topoint(geometry)
WHERE ST_GeometryType(geometry) <> 'ST_Point';

ANALYZE osm_island_polygon;
