-- etldoc:  osm_island_polygon ->  osm_island_polygon
CREATE FUNCTION convert_island_polygon_point() RETURNS VOID AS $$
BEGIN
  UPDATE osm_island_polygon  SET geometry=topoint(geometry) WHERE ST_GeometryType(geometry) <> 'ST_Point';
  ANALYZE osm_island_polygon;
END;
$$ LANGUAGE plpgsql;

SELECT convert_island_polygon_point();

-- Handle updates

CREATE SCHEMA place_island;

CREATE TABLE IF NOT EXISTS place_island.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION place_island.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO place_island.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;    
$$ language plpgsql;

CREATE OR REPLACE FUNCTION place_island.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh place_island';
    SELECT convert_island_polygon_point();
    DELETE FROM place_island.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_island_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE place_island.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON place_island.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE place_island.refresh();
