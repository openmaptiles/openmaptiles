ALTER TABLE osm_park_polygon ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen1 ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen2 ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen3 ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen4 ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen5 ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen6 ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen7 ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_park_polygon_gen8 ADD COLUMN IF NOT EXISTS geometry_point geometry;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen1;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen2;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen3;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen4;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen5;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen6;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen7;
DROP TRIGGER IF EXISTS update_row ON osm_park_polygon_gen8;

-- etldoc:  osm_park_polygon ->  osm_park_polygon
-- etldoc:  osm_park_polygon_gen1 ->  osm_park_polygon_gen1
-- etldoc:  osm_park_polygon_gen2 ->  osm_park_polygon_gen2
-- etldoc:  osm_park_polygon_gen3 ->  osm_park_polygon_gen3
-- etldoc:  osm_park_polygon_gen4 ->  osm_park_polygon_gen4
-- etldoc:  osm_park_polygon_gen5 ->  osm_park_polygon_gen5
-- etldoc:  osm_park_polygon_gen6 ->  osm_park_polygon_gen6
-- etldoc:  osm_park_polygon_gen7 ->  osm_park_polygon_gen7
-- etldoc:  osm_park_polygon_gen8 ->  osm_park_polygon_gen8
CREATE OR REPLACE FUNCTION update_osm_park_polygon() RETURNS VOID AS $$
BEGIN
  UPDATE osm_park_polygon
  SET tags = update_tags(tags, geometry),
      geometry_point = st_centroid(geometry);

  UPDATE osm_park_polygon_gen1
  SET tags = update_tags(tags, geometry),
      geometry_point = st_centroid(geometry);

  UPDATE osm_park_polygon_gen2
  SET tags = update_tags(tags, geometry),
      geometry_point = st_centroid(geometry);

  UPDATE osm_park_polygon_gen3
  SET tags = update_tags(tags, geometry),
      geometry_point = st_centroid(geometry);

  UPDATE osm_park_polygon_gen4
  SET tags = update_tags(tags, geometry),
      geometry_point = st_centroid(geometry);

  UPDATE osm_park_polygon_gen5
  SET tags = update_tags(tags, geometry),
      geometry_point = st_centroid(geometry);

  UPDATE osm_park_polygon_gen6
  SET tags = update_tags(tags, geometry),
      geometry_point = st_centroid(geometry);

  UPDATE osm_park_polygon_gen7
  SET tags = update_tags(tags, geometry),
      geometry_point = st_centroid(geometry);

  UPDATE osm_park_polygon_gen8
  SET tags = update_tags(tags, geometry),
      geometry_point = st_centroid(geometry);

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_park_polygon();
CREATE INDEX IF NOT EXISTS osm_park_polygon_point_geom_idx ON osm_park_polygon USING gist(geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen1_point_geom_idx ON osm_park_polygon_gen1 USING gist(geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen2_point_geom_idx ON osm_park_polygon_gen2 USING gist(geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen3_point_geom_idx ON osm_park_polygon_gen3 USING gist(geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen4_point_geom_idx ON osm_park_polygon_gen4 USING gist(geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen5_point_geom_idx ON osm_park_polygon_gen5 USING gist(geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen6_point_geom_idx ON osm_park_polygon_gen6 USING gist(geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen7_point_geom_idx ON osm_park_polygon_gen7 USING gist(geometry_point);
CREATE INDEX IF NOT EXISTS osm_park_polygon_gen8_point_geom_idx ON osm_park_polygon_gen8 USING gist(geometry_point);


CREATE OR REPLACE FUNCTION update_osm_park_polygon_row()
  RETURNS TRIGGER
AS
$BODY$
BEGIN
  NEW.tags = update_tags(NEW.tags, NEW.geometry);
  NEW.geometry_point = st_centroid(NEW.geometry);
  RETURN NEW;
END;
$BODY$
LANGUAGE plpgsql;

CREATE TRIGGER update_row
BEFORE INSERT OR UPDATE ON osm_park_polygon
FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
BEFORE INSERT OR UPDATE ON osm_park_polygon_gen1
FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
BEFORE INSERT OR UPDATE ON osm_park_polygon_gen2
FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
BEFORE INSERT OR UPDATE ON osm_park_polygon_gen3
FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
BEFORE INSERT OR UPDATE ON osm_park_polygon_gen4
FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
BEFORE INSERT OR UPDATE ON osm_park_polygon_gen5
FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
BEFORE INSERT OR UPDATE ON osm_park_polygon_gen6
FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
BEFORE INSERT OR UPDATE ON osm_park_polygon_gen7
FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();

CREATE TRIGGER update_row
BEFORE INSERT OR UPDATE ON osm_park_polygon_gen8
FOR EACH ROW
EXECUTE PROCEDURE update_osm_park_polygon_row();



