DROP TRIGGER IF EXISTS trigger_update_point ON osm_peak_point;

-- etldoc:  osm_peak_point ->  osm_peak_point
-- etldoc:  osm_peak_point ->  osm_peak_point
CREATE OR REPLACE FUNCTION update_osm_peak_point(new_osm_id bigint) RETURNS void AS
$$
UPDATE osm_peak_point
SET tags = update_tags(tags, geometry)
WHERE (new_osm_id IS NULL OR osm_id = new_osm_id)
  AND COALESCE(tags -> 'name:latin', tags -> 'name:nonlatin', tags -> 'name_int') IS NULL
  AND tags != update_tags(tags, geometry)
$$ LANGUAGE SQL;

SELECT update_osm_peak_point(NULL);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS mountain_peak_point;

CREATE OR REPLACE FUNCTION mountain_peak_point.update() RETURNS trigger AS
$$
BEGIN
    PERFORM update_osm_peak_point(new.osm_id);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trigger_update_point
    AFTER INSERT OR UPDATE
    ON osm_peak_point
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE mountain_peak_point.update();
