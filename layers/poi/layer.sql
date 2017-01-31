
-- etldoc: layer_poi[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_poi | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION poi.layer_poi(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, class text, subclass text, "rank" int) AS $$
    SELECT osm_id, geometry, NULLIF(name, '') AS name, NULLIF(name_en, '') AS name_en, poi.poi_class(subclass) AS class, subclass,
        row_number() OVER (
            PARTITION BY LabelGrid(geometry, 100 * pixel_width)
            ORDER BY CASE WHEN name = '' THEN 2000 ELSE poi.poi_class_rank(poi.poi_class(subclass)) END ASC
        )::int AS "rank"
    FROM (
        -- etldoc: osm_poi_point ->  layer_poi:z14_
        SELECT * FROM osm_poi_point
            WHERE geometry && bbox
                AND zoom_level >= 14
        UNION ALL
        -- etldoc: osm_poi_polygon ->  layer_poi:z14_
        SELECT * FROM osm_poi_polygon
            WHERE geometry && bbox
                AND zoom_level >= 14
        ) as poi_union
    ORDER BY "rank"
    ;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION poi.delete() RETURNS VOID AS $$
BEGIN
  DROP TRIGGER IF EXISTS trigger_flag ON osm_poi_polygon;
  DROP TRIGGER IF EXISTS trigger_refresh ON poi.updates;
  DROP SCHEMA IF EXISTS poi CASCADE;
  DROP TABLE IF EXISTS osm_poi_point CASCADE;
  DROP TABLE IF EXISTS osm_poi_polygon CASCADE;
  DROP TABLE IF EXISTS osm_park_polygon CASCADE;
END;
$$ LANGUAGE plpgsql;
