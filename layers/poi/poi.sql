-- etldoc: layer_poi[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_poi | <z12> z12 | <z13> z13 | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_poi(bbox geometry, zoom_level integer, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                name     text,
                name_en  text,
                name_de  text,
                tags     hstore,
                class    text,
                subclass text,
                agg_stop integer,
                layer    integer,
                level    integer,
                indoor   integer,
                "rank"   int
            )
AS
$$
SELECT osm_id_hash AS osm_id,
       geometry,
       NULLIF(name, '') AS name,
       COALESCE(NULLIF(name_en, ''), name) AS name_en,
       COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
       tags,
       poi_class(subclass, mapping_key) AS class,
       CASE
           WHEN subclass = 'information'
               THEN NULLIF(information, '')
           WHEN subclass = 'place_of_worship'
               THEN NULLIF(religion, '')
           WHEN subclass = 'pitch'
               THEN NULLIF(sport, '')
           ELSE subclass
           END AS subclass,
       agg_stop,
       NULLIF(layer, 0) AS layer,
       "level",
       CASE WHEN indoor = TRUE THEN 1 END AS indoor,
       row_number() OVER (
           PARTITION BY LabelGrid(geometry, 100 * pixel_width)
           ORDER BY CASE WHEN name = '' THEN 2000 ELSE poi_class_rank(poi_class(subclass, mapping_key)) END ASC
           )::int AS "rank"
FROM (
         -- etldoc: osm_poi_point ->  layer_poi:z12
         -- etldoc: osm_poi_point ->  layer_poi:z13
         SELECT *,
                osm_id * 10 AS osm_id_hash
         FROM osm_poi_point
         WHERE geometry && bbox
           AND zoom_level BETWEEN 12 AND 13
           AND ((subclass = 'station' AND mapping_key = 'railway')
             OR subclass IN ('halt', 'ferry_terminal'))

         UNION ALL

         -- etldoc: osm_poi_point ->  layer_poi:z14_
         SELECT *,
                osm_id * 10 AS osm_id_hash
         FROM osm_poi_point
         WHERE geometry && bbox
           AND zoom_level >= 14

         UNION ALL

         -- etldoc: osm_poi_polygon ->  layer_poi:z12
         -- etldoc: osm_poi_polygon ->  layer_poi:z13
         -- etldoc: osm_poi_polygon ->  layer_poi:z14_
         SELECT *,
                NULL::integer AS agg_stop,
                CASE
                    WHEN osm_id < 0 THEN -osm_id * 10 + 4
                    ELSE osm_id * 10 + 1
                    END AS osm_id_hash
         FROM osm_poi_polygon
         WHERE zoom_level > 9 AND geometry && bbox AND
           CASE
               WHEN zoom_level >= 14 THEN TRUE
               WHEN zoom_level >= 12 AND
                 ((subclass = 'station' AND mapping_key = 'railway')
                 OR subclass IN ('halt', 'ferry_terminal')) THEN TRUE 
               WHEN zoom_level BETWEEN 10 AND 14 THEN
                 subclass IN ('university', 'college') AND
                 POWER(4,zoom_level)
                 -- Compute percentage of the earth's surface covered by this feature (approximately)
                 -- The constant below is 111,842^2 * 180 * 180, where 111,842 is the length of one degree of latitude at the equator in meters.
                 * area / (405279708033600 * COS(ST_Y(ST_Transform(geometry,4326))*PI()/180))
                 -- Match features that are at least 10% of a tile at this zoom
                 > 0.10
               ELSE FALSE END
     ) AS poi_union
ORDER BY "rank"
$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;
-- TODO: Check if the above can be made STRICT -- i.e. if pixel_width could be NULL
