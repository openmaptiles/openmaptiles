DROP TRIGGER IF EXISTS trigger_flag ON osm_poi_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON poi.updates;

-- etldoc:  osm_poi_polygon ->  osm_poi_polygon

CREATE OR REPLACE FUNCTION convert_poi_point() RETURNS VOID AS $$
BEGIN
  UPDATE osm_poi_polygon
  SET geometry =
           CASE WHEN ST_NPoints(ST_ConvexHull(geometry))=ST_NPoints(geometry)
           THEN ST_Centroid(geometry)
           ELSE ST_PointOnSurface(geometry)
    END
  WHERE ST_GeometryType(geometry) <> 'ST_Point';
  ANALYZE osm_poi_polygon;
END;
$$ LANGUAGE plpgsql;

SELECT convert_poi_point();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS poi;

CREATE TABLE IF NOT EXISTS poi.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION poi.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO poi.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;    
$$ language plpgsql;

CREATE OR REPLACE FUNCTION poi.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh poi';
    PERFORM convert_poi_point();
    DELETE FROM poi.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_poi_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE poi.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON poi.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE poi.refresh();
