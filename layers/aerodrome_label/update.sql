DROP TRIGGER IF EXISTS trigger_flag ON osm_aerodrome_label_point;
DROP TRIGGER IF EXISTS trigger_refresh ON aerodrome_label.updates;

-- etldoc: osm_aerodrome_label_point -> osm_aerodrome_label_point
CREATE OR REPLACE FUNCTION update_aerodrome_label_point() RETURNS VOID AS $$
BEGIN
  UPDATE osm_aerodrome_label_point
  SET geometry = ST_Centroid(geometry)
  WHERE ST_GeometryType(geometry) <> 'ST_Point';

  UPDATE osm_aerodrome_label_point
  SET tags = delete_empty_keys(tags) || get_basic_names(tags, geometry)
  WHERE COALESCE(tags->'name:latin', tags->'name:nonlatin', tags->'name_int') IS NULL;
END;
$$ LANGUAGE plpgsql;

SELECT update_aerodrome_label_point();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS aerodrome_label;

CREATE TABLE IF NOT EXISTS aerodrome_label.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION aerodrome_label.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO aerodrome_label.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION aerodrome_label.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh aerodrome_label';
    PERFORM update_aerodrome_label_point();
    DELETE FROM aerodrome_label.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE ON osm_aerodrome_label_point
    FOR EACH STATEMENT
    EXECUTE PROCEDURE aerodrome_label.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON aerodrome_label.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE aerodrome_label.refresh();
