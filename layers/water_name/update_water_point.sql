DROP TRIGGER IF EXISTS trigger_delete_point ON osm_water_polygon;
DROP TRIGGER IF EXISTS trigger_update_point ON osm_water_polygon;
DROP TRIGGER IF EXISTS trigger_insert_point ON osm_water_polygon;

CREATE OR REPLACE VIEW osm_water_point_view AS
SELECT wp.osm_id,
       ST_PointOnSurface(wp.geometry) AS geometry,
       wp.name,
       wp.name_en,
       wp.name_de,
       update_tags(wp.tags, ST_PointOnSurface(wp.geometry)) AS tags,
       ST_Area(wp.geometry) AS area,
       wp.is_intermittent
FROM osm_water_polygon AS wp
         LEFT JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
WHERE ll.osm_id IS NULL
  AND wp.name <> ''
  AND ST_IsValid(wp.geometry);

-- etldoc:  osm_water_polygon ->  osm_water_point
-- etldoc:  lake_centerline ->  osm_water_point
CREATE TABLE IF NOT EXISTS osm_water_point AS
SELECT *
FROM osm_water_point_view;
DO
$$
    BEGIN
        ALTER TABLE osm_water_point
            ADD CONSTRAINT osm_water_point_pk PRIMARY KEY (osm_id);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'primary key osm_water_point_pk already exists in osm_water_point.';
    END;
$$;
CREATE INDEX IF NOT EXISTS osm_water_point_geometry_idx ON osm_water_point USING gist (geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS water_point;

CREATE OR REPLACE FUNCTION water_point.delete() RETURNS trigger AS
$$
BEGIN
    DELETE
    FROM osm_water_point
    WHERE osm_water_point.osm_id = OLD.osm_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION water_point.update() RETURNS trigger AS
$$
BEGIN
    UPDATE osm_water_point
    SET (osm_id, geometry, name, name_en, name_de, tags, area, is_intermittent) =
            (SELECT * FROM osm_water_point_view WHERE osm_water_point_view.osm_id = NEW.osm_id)
    WHERE osm_water_point.osm_id = NEW.osm_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION water_point.insert() RETURNS trigger AS
$$
BEGIN
    INSERT INTO osm_water_point
    SELECT *
    FROM osm_water_point_view
    WHERE osm_water_point_view.osm_id = NEW.osm_id
    -- May happen in case we replay update
    ON CONFLICT ON CONSTRAINT osm_water_point_pk
    DO NOTHING;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_delete_point
    AFTER DELETE
    ON osm_water_polygon
    FOR EACH ROW
EXECUTE PROCEDURE water_point.delete();

CREATE TRIGGER trigger_update_point
    AFTER UPDATE
    ON osm_water_polygon
    FOR EACH ROW
EXECUTE PROCEDURE water_point.update();

CREATE TRIGGER trigger_insert_point
    AFTER INSERT
    ON osm_water_polygon
    FOR EACH ROW
EXECUTE PROCEDURE water_point.insert();
