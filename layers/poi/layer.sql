
-- etldoc: layer_poi[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_poi | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_poi(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, name_de text, class text, subclass text, "rank" int) AS $$
    SELECT osm_id, geometry, NULLIF(name, '') AS name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
    poi_class(subclass) AS class, subclass,
        row_number() OVER (
            PARTITION BY LabelGrid(geometry, 100 * pixel_width)
            ORDER BY CASE WHEN name = '' THEN 2000 ELSE poi_class_rank(poi_class(subclass)) END ASC
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
