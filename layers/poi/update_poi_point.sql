DROP TRIGGER IF EXISTS trigger_flag ON osm_poi_point;
DROP TRIGGER IF EXISTS trigger_refresh ON poi_point.updates;

-- etldoc:  osm_poi_point ->  osm_poi_point
CREATE OR REPLACE FUNCTION update_osm_poi_point() RETURNS VOID AS $$
BEGIN
  UPDATE osm_poi_point
    SET subclass = 'subway'
    WHERE station = 'subway' and subclass='station';

  UPDATE osm_poi_point
    SET subclass = 'halt'
    WHERE funicular = 'yes' and subclass='station';

  UPDATE osm_poi_point
  SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry)
  WHERE COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL;

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_poi_point();

CREATE OR REPLACE FUNCTION update_osm_poi_point_agg() RETURNS VOID AS $$
BEGIN
  UPDATE osm_poi_point p
  SET agg_stop = CASE
      WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
        THEN 1
      ELSE NULL
  END;

  UPDATE osm_poi_point p
    SET agg_stop = (
      CASE
        WHEN p.subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
            AND r.rk IS NULL OR r.rk = 1
          THEN 1
        ELSE NULL
      END)
    FROM osm_poi_stop_rank r
    WHERE p.osm_id = r.osm_id
  ;

END;
$$ LANGUAGE plpgsql;

-- Handle updates

CREATE SCHEMA IF NOT EXISTS poi_point;

CREATE TABLE IF NOT EXISTS poi_point.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION poi_point.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO poi_point.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION poi_point.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh poi_point';
    PERFORM update_osm_poi_point();
    REFRESH MATERIALIZED VIEW osm_poi_stop_centroid;
    REFRESH MATERIALIZED VIEW osm_poi_stop_rank;
    PERFORM update_osm_poi_point_agg();
    DELETE FROM poi_point.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_poi_point
    FOR EACH STATEMENT
    EXECUTE PROCEDURE poi_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON poi_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE poi_point.refresh();
