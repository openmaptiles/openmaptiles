DROP TRIGGER IF EXISTS trigger_flag ON osm_waterway_linestring;
DROP TRIGGER IF EXISTS trigger_refresh ON osm_waterway_linestring;

DO
$$
    BEGIN
        UPDATE osm_waterway_linestring
        SET tags = update_tags(tags, geometry);
    END
$$;


-- Handle updates

CREATE SCHEMA IF NOT EXISTS waterway_linestring;
CREATE OR REPLACE FUNCTION waterway_linestring.refresh() RETURNS trigger AS
$$
BEGIN
    --     RAISE NOTICE 'Refresh waterway_linestring %', NEW.osm_id;
    NEW.tags = update_tags(NEW.tags, NEW.geometry);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_refresh
    BEFORE INSERT OR UPDATE
    ON osm_waterway_linestring
    FOR EACH ROW
EXECUTE PROCEDURE waterway_linestring.refresh();
