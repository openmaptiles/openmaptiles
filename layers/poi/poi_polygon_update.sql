-- etldoc:  osm_poi_polygon ->  osm_poi_polygon

CREATE FUNCTION convert_poi_point() RETURNS VOID AS $$
BEGIN
  UPDATE osm_poi_polygon SET geometry=topoint(geometry) WHERE ST_GeometryType(geometry) <> 'ST_Point';
  ANALYZE osm_poi_polygon;
END;
$$ LANGUAGE plpgsql;

SELECT convert_poi_point();

