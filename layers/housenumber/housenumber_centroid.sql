
-- etldoc: osm_housenumber_point -> osm_housenumber_point
UPDATE osm_housenumber_point SET geometry=topoint(geometry)
WHERE ST_GeometryType(geometry) <> 'ST_Point';
