DROP TRIGGER IF EXISTS trigger_store ON osm_water_polygon;
DROP TRIGGER IF EXISTS trigger_flag ON osm_water_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON water_name.updates;

CREATE INDEX IF NOT EXISTS lake_centerline_osm_id_idx ON lake_centerline (osm_id);
CREATE INDEX IF NOT EXISTS osm_water_polygon_update_idx ON osm_water_polygon (name, ST_IsValid(geometry))
    WHERE name <> '' AND ST_IsValid(geometry);;

CREATE OR REPLACE VIEW osm_water_lakeline_view AS
SELECT wp.osm_id,
       ll.wkb_geometry AS geometry,
       name,
       name_en,
       name_de,
       update_tags(tags, ll.wkb_geometry) AS tags,
       ST_Area(wp.geometry) AS area,
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

-- etldoc:  osm_water_polygon ->  osm_water_point_view
-- etldoc:  lake_centerline ->  osm_water_point_view
CREATE OR REPLACE VIEW osm_water_point_view AS
SELECT wp.osm_id,
       ST_PointOnSurface(wp.geometry) AS geometry,
       wp.name,
       wp.name_en,
       wp.name_de,
       CASE
           WHEN "natural" = 'bay' THEN 'bay'
           WHEN place = 'sea' THEN 'sea'
           ELSE 'lake'
       END AS class,
       update_tags(wp.tags, ST_PointOnSurface(wp.geometry)) AS tags,
       -- Area of the feature in square meters
       ST_Area(wp.geometry) AS area,
       wp.is_intermittent
FROM osm_water_polygon AS wp
         LEFT JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
WHERE ll.osm_id IS NULL
  AND wp.name <> ''
  AND ST_IsValid(wp.geometry);

-- etldoc:  osm_water_point_view ->  osm_water_point_earth_view
CREATE OR REPLACE VIEW osm_water_point_earth_view AS
SELECT osm_id,
       geometry,
       name,
       name_en,
       name_de,
       class,
       tags,
       -- Percentage of the earth's surface covered by this feature (approximately)
       -- The constant below is 111,842^2 * 180 * 180, where 111,842 is the length of one degree of latitude at the equator in meters.
       area / (405279708033600 * COS(ST_Y(ST_Transform(geometry,4326))*PI()/180)) as earth_area,
       is_intermittent
FROM osm_water_point_view;

-- etldoc:  osm_water_point_earth_view ->  osm_water_point
CREATE TABLE IF NOT EXISTS osm_water_point AS
SELECT *
FROM osm_water_point_earth_view;
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

CREATE SCHEMA IF NOT EXISTS water_name;

CREATE TABLE IF NOT EXISTS water_name.osm_ids
(
    osm_id bigint,
    is_old bool,
    PRIMARY KEY (osm_id, is_old)
);

CREATE OR REPLACE FUNCTION update_osm_water_name() RETURNS void AS $$
BEGIN
    DELETE FROM osm_water_lakeline
    WHERE EXISTS(
        SELECT NULL
        FROM water_name.osm_ids
        WHERE water_name.osm_ids.osm_id = osm_water_lakeline.osm_id
              AND water_name.osm_ids.is_old IS TRUE
    );

    INSERT INTO osm_water_lakeline
    SELECT * FROM osm_water_lakeline_view
    WHERE EXISTS(
        SELECT NULL
        FROM water_name.osm_ids
        WHERE water_name.osm_ids.osm_id = osm_water_lakeline_view.osm_id
              AND water_name.osm_ids.is_old IS FALSE
    ) ON CONFLICT (osm_id) DO UPDATE SET geometry = excluded.geometry, name = excluded.name, name_en = excluded.name_en,
                                         name_de = excluded.name_de, tags = excluded.tags, area = excluded.area,
                                         is_intermittent = excluded.is_intermittent;

    DELETE FROM osm_water_point
    WHERE EXISTS(
        SELECT NULL
        FROM water_name.osm_ids
        WHERE water_name.osm_ids.osm_id = osm_water_point.osm_id
              AND water_name.osm_ids.is_old IS TRUE
    );

    INSERT INTO osm_water_point
    SELECT * FROM osm_water_point_earth_view
    WHERE EXISTS(
        SELECT NULL
        FROM water_name.osm_ids
        WHERE water_name.osm_ids.osm_id = osm_water_point_earth_view.osm_id
              AND water_name.osm_ids.is_old IS FALSE
    ) ON CONFLICT (osm_id) DO UPDATE SET geometry = excluded.geometry, name = excluded.name, name_en = excluded.name_en,
                                         name_de = excluded.name_de, class = excluded.class, tags = excluded.tags,
                                         earth_area = excluded.earth_area, is_intermittent = excluded.is_intermittent;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION water_name.store() RETURNS trigger AS $$
BEGIN
    IF (tg_op = 'DELETE') THEN
        INSERT INTO water_name.osm_ids (osm_id, is_old) VALUES (OLD.osm_id, TRUE) ON CONFLICT (osm_id, is_old) DO NOTHING;
    ELSE
        INSERT INTO water_name.osm_ids (osm_id, is_old) VALUES (NEW.osm_id, FALSE) ON CONFLICT (osm_id, is_old) DO NOTHING;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS water_name.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);
CREATE OR REPLACE FUNCTION water_name.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO water_name.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION water_name.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh water_name';

    -- Analyze tracking and source tables before performing update
    ANALYZE water_name.osm_ids;
    ANALYZE osm_water_lakeline;
    ANALYZE osm_water_point;

    PERFORM update_osm_water_name();
    -- noinspection SqlWithoutWhere
    DELETE FROM water_name.osm_ids;
    -- noinspection SqlWithoutWhere
    DELETE FROM water_name.updates;

    RAISE LOG 'Refresh water_name done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_store
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_water_polygon
    FOR EACH ROW
EXECUTE PROCEDURE water_name.store();

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_water_polygon
    FOR EACH STATEMENT
EXECUTE PROCEDURE water_name.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON water_name.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE water_name.refresh();
