ALTER TABLE osm_boundary_polygon
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z13
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z12
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z11
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z10
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z9
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z8
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z7
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z6
    ADD COLUMN IF NOT EXISTS geometry_point geometry;
ALTER TABLE osm_boundary_polygon_gen_z5
    ADD COLUMN IF NOT EXISTS geometry_point geometry;

DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z13;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z12;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z11;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z10;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z9;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z8;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z7;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z6;
DROP TRIGGER IF EXISTS update_row ON osm_boundary_polygon_gen_z5;

-- etldoc:  osm_boundary_polygon ->  osm_boundary_polygon
-- etldoc:  osm_boundary_polygon_gen_z13 ->  osm_boundary_polygon_gen_z13
-- etldoc:  osm_boundary_polygon_gen_z12 ->  osm_boundary_polygon_gen_z12
-- etldoc:  osm_boundary_polygon_gen_z11 ->  osm_boundary_polygon_gen_z11
-- etldoc:  osm_boundary_polygon_gen_z10 ->  osm_boundary_polygon_gen_z10
-- etldoc:  osm_boundary_polygon_gen_z9 ->  osm_boundary_polygon_gen_z9
-- etldoc:  osm_boundary_polygon_gen_z8 ->  osm_boundary_polygon_gen_z8
-- etldoc:  osm_boundary_polygon_gen_z7 ->  osm_boundary_polygon_gen_z7
-- etldoc:  osm_boundary_polygon_gen_z6 ->  osm_boundary_polygon_gen_z6
-- etldoc:  osm_boundary_polygon_gen_z5 ->  osm_boundary_polygon_gen_z5
CREATE OR REPLACE FUNCTION update_osm_boundary_polygon() RETURNS void AS
$$
BEGIN
    UPDATE osm_boundary_polygon
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z13
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z12
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z11
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z10
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z9
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z8
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z7
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z6
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

    UPDATE osm_boundary_polygon_gen_z5
    SET tags           = update_tags(tags, geometry),
        geometry_point = ST_PointOnSurface(geometry);

END;
$$ LANGUAGE plpgsql;

SELECT update_osm_boundary_polygon();
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_point_geom_idx ON osm_boundary_polygon USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z13_point_geom_idx ON osm_boundary_polygon_gen_z13 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z12_point_geom_idx ON osm_boundary_polygon_gen_z12 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z11_point_geom_idx ON osm_boundary_polygon_gen_z11 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z10_point_geom_idx ON osm_boundary_polygon_gen_z10 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z9_point_geom_idx ON osm_boundary_polygon_gen_z9 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z8_point_geom_idx ON osm_boundary_polygon_gen_z8 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z7_point_geom_idx ON osm_boundary_polygon_gen_z7 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z6_point_geom_idx ON osm_boundary_polygon_gen_z6 USING gist (geometry_point);
CREATE INDEX IF NOT EXISTS osm_boundary_polygon_gen_z5_point_geom_idx ON osm_boundary_polygon_gen_z5 USING gist (geometry_point);

CREATE OR REPLACE FUNCTION update_osm_boundary_polygon_row()
    RETURNS trigger
AS
$$
BEGIN
    NEW.tags = update_tags(NEW.tags, NEW.geometry);
    NEW.geometry_point = ST_PointOnSurface(NEW.geometry);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z13
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z12
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z11
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z10
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z9
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z8
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z7
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z6
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();

CREATE TRIGGER update_row
    BEFORE INSERT OR UPDATE
    ON osm_boundary_polygon_gen_z5
    FOR EACH ROW
EXECUTE PROCEDURE update_osm_boundary_polygon_row();
