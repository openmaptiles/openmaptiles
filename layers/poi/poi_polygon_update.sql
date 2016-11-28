-- etldoc:  osm_poi_polygon ->  osm_poi_polygon
UPDATE osm_poi_polygon  SET geometry=topoint(geometry)
WHERE ST_GeometryType(geometry) <> 'ST_Point';

ANALYZE osm_poi_polygon;
