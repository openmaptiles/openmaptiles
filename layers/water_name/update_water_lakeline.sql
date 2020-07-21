DROP TRIGGER IF EXISTS trigger_delete_line ON osm_water_polygon;
DROP TRIGGER IF EXISTS trigger_update_line ON osm_water_polygon;
DROP TRIGGER IF EXISTS trigger_insert_line ON osm_water_polygon;

CREATE OR REPLACE VIEW osm_water_lakeline_view AS
SELECT wp.osm_id,
       ll.wkb_geometry                    AS geometry,
       name,
       name_en,
       name_de,
       update_tags(tags, ll.wkb_geometry) AS tags,
       ST_Area(wp.geometry)               AS area,
       is_intermittent
FROM osm_water_polygon AS wp
         INNER JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
WHERE wp.name <> ''
  AND ST_IsValid(wp.geometry);

-- etldoc:  osm_water_polygon ->  osm_water_lakeline
-- etldoc:  lake_centerline  ->  osm_water_lakeline
CREATE TABLE IF NOT EXISTS osm_water_lakeline AS
SELECT *
FROM osm_water_lakeline_view;
DO
$$
    BEGIN
        ALTER TABLE osm_water_lakeline
            ADD CONSTRAINT osm_water_lakeline_pk PRIMARY KEY (osm_id);
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'primary key osm_water_lakeline_pk already exists in osm_water_lakeline.';
    END;
$$;
CREATE INDEX IF NOT EXISTS osm_water_lakeline_geometry_idx ON osm_water_lakeline USING gist (geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS water_lakeline;

CREATE OR REPLACE FUNCTION water_lakeline.delete() RETURNS trigger AS
$$
BEGIN
    DELETE
    FROM osm_water_lakeline
    WHERE osm_water_lakeline.osm_id = OLD.osm_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION water_lakeline.update() RETURNS trigger AS
$$
BEGIN
    UPDATE osm_water_lakeline
    SET (osm_id, geometry, name, name_en, name_de, tags, area, is_intermittent) =
            (SELECT * FROM osm_water_lakeline_view WHERE osm_water_lakeline_view.osm_id = NEW.osm_id)
    WHERE osm_water_lakeline.osm_id = NEW.osm_id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION water_lakeline.insert() RETURNS trigger AS
$$
BEGIN
    INSERT INTO osm_water_lakeline
    SELECT *
    FROM osm_water_lakeline_view
    WHERE osm_water_lakeline_view.osm_id = NEW.osm_id
    -- May happen in case we replay update
    ON CONFLICT ON CONSTRAINT osm_water_point_pk
    DO NOTHING;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_delete_line
    AFTER DELETE
    ON osm_water_polygon
    FOR EACH ROW
EXECUTE PROCEDURE water_lakeline.delete();

CREATE TRIGGER trigger_update_line
    AFTER UPDATE
    ON osm_water_polygon
    FOR EACH ROW
EXECUTE PROCEDURE water_lakeline.update();

CREATE TRIGGER trigger_insert_line
    AFTER INSERT
    ON osm_water_polygon
    FOR EACH ROW
EXECUTE PROCEDURE water_lakeline.insert();
