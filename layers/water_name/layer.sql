CREATE SCHEMA IF NOT EXISTS water_name;
-- etldoc: layer_water_name[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_water_name | <z9_13> z9_13 | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION water_name.layer_water_name(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, class text) AS $$
    -- etldoc: osm_water_lakeline ->  layer_water_name:z9_13
    -- etldoc: osm_water_lakeline ->  layer_water_name:z14_
    SELECT osm_id, geometry, name, name_en, 'lake'::text AS class
    FROM water_lakeline.osm_water_lakeline
    WHERE geometry && bbox
      AND ((zoom_level BETWEEN 9 AND 13 AND LineLabel(zoom_level, NULLIF(name, ''), geometry))
        OR (zoom_level >= 14))
    -- etldoc: osm_water_point ->  layer_water_name:z9_13
    -- etldoc: osm_water_point ->  layer_water_name:z14_
    UNION ALL
    SELECT osm_id, geometry, name, name_en, 'lake'::text AS class
    FROM water_point.osm_water_point
    WHERE geometry && bbox AND (
        (zoom_level BETWEEN 9 AND 13 AND area > 70000*2^(20-zoom_level))
        OR (zoom_level >= 14)
    )
    -- etldoc: osm_marine_point ->  layer_water_name:z0_14_
    UNION ALL
    SELECT osm_id, geometry, name, name_en, place::text AS class
    FROM osm_marine_point
    WHERE geometry && bbox AND (
        place = 'ocean'
        OR (zoom_level >= 1 AND zoom_level <= "rank" AND "rank" IS NOT NULL)
        OR (zoom_level >= 8)
    );
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION water_name.delete() RETURNS VOID AS $$
BEGIN
  DROP TRIGGER IF EXISTS trigger_flag_line ON osm_water_polygon;
  DROP TRIGGER IF EXISTS trigger_refresh ON water_lakeline.updates;
  DROP SCHEMA IF EXISTS water_lakeline CASCADE;

  DROP TRIGGER IF EXISTS trigger_flag_point ON osm_water_polygon;
  DROP TRIGGER IF EXISTS trigger_refresh ON water_point.updates;
  DROP SCHEMA IF EXISTS water_point CASCADE;

  DROP TRIGGER IF EXISTS trigger_flag ON osm_marine_point;
  DROP TRIGGER IF EXISTS trigger_refresh ON water_name_marine.updates;
  DROP SCHEMA IF EXISTS water_name_marine CASCADE;

  DROP SCHEMA IF EXISTS water_name CASCADE;

  DROP TABLE IF EXISTS osm_marine_point CASCADE;
END;
$$ LANGUAGE plpgsql;
