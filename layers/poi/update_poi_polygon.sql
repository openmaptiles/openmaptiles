DROP TRIGGER IF EXISTS trigger_flag ON osm_poi_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON poi_polygon.updates;

-- etldoc:  osm_poi_polygon ->  osm_poi_polygon

CREATE OR REPLACE FUNCTION update_poi_polygon() RETURNS VOID AS $$
BEGIN
  UPDATE osm_poi_polygon
  SET geometry =
           CASE WHEN ST_NPoints(ST_ConvexHull(geometry))=ST_NPoints(geometry)
           THEN ST_Centroid(geometry)
           ELSE ST_PointOnSurface(geometry)
    END
  WHERE ST_GeometryType(geometry) <> 'ST_Point';

  UPDATE osm_poi_polygon
  SET subclass = 'subway'
  WHERE station = 'subway' and subclass='station';

  UPDATE osm_poi_polygon
  SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry)
  WHERE COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL;

  ANALYZE osm_poi_polygon;
END;
$$ LANGUAGE plpgsql;

SELECT update_poi_polygon();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS poi_polygon;

CREATE TABLE IF NOT EXISTS poi_polygon.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION poi_polygon.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO poi_polygon.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION poi_polygon.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh poi_polygon';
    PERFORM update_poi_polygon();
    DELETE FROM poi_polygon.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_poi_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE poi_polygon.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON poi_polygon.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE poi_polygon.refresh();
