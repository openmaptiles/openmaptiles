
-- etldoc: osm_housenumber_point -> osm_housenumber_point
CREATE FUNCTION convert_housenumber_point() RETURNS VOID AS $$
BEGIN
  UPDATE osm_housenumber_point SET geometry=topoint(geometry) WHERE ST_GeometryType(geometry) <> 'ST_Point';
END;
$$ LANGUAGE plpgsql;

SELECT convert_housenumber_point();
