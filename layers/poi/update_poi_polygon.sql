DROP TRIGGER IF EXISTS trigger_flag ON osm_poi_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON poi_polygon.updates;

-- etldoc:  osm_poi_polygon ->  osm_poi_polygon

CREATE OR REPLACE FUNCTION update_poi_polygon() RETURNS void AS
$$
BEGIN
    UPDATE osm_poi_polygon
    SET geometry =
            CASE
                WHEN ST_NPoints(ST_ConvexHull(geometry)) = ST_NPoints(geometry)
                    THEN ST_Centroid(geometry)
                ELSE ST_PointOnSurface(geometry)
                END
    WHERE ST_GeometryType(geometry) <> 'ST_Point';

    UPDATE osm_poi_polygon
    SET subclass = 'subway'
    WHERE station = 'subway'
      AND subclass = 'station';

    UPDATE osm_poi_polygon
    SET subclass = 'halt'
    WHERE funicular = 'yes'
      AND subclass = 'station';

    UPDATE osm_poi_polygon
    SET tags = update_tags(tags, geometry)
    WHERE COALESCE(tags -> 'name:latin', tags -> 'name:nonlatin', tags -> 'name_int') IS NULL;

    ANALYZE osm_poi_polygon;
END;
$$ LANGUAGE plpgsql;

SELECT update_poi_polygon();

-- Handle updates

CREATE SCHEMA IF NOT EXISTS poi_polygon;

CREATE TABLE IF NOT EXISTS poi_polygon.updates
(
    id serial PRIMARY KEY,
    t  text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION poi_polygon.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO poi_polygon.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION poi_polygon.refresh() RETURNS trigger AS
$$
BEGIN
    RAISE LOG 'Refresh poi_polygon';
    PERFORM update_poi_polygon();
    -- noinspection SqlWithoutWhere
    DELETE FROM poi_polygon.updates;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_poi_polygon
    FOR EACH STATEMENT
EXECUTE PROCEDURE poi_polygon.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON poi_polygon.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE poi_polygon.refresh();
