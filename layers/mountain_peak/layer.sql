CREATE OR REPLACE FUNCTION layer_mountain_peak(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, ele int, ele_ft int, "rank" int) AS $$
   -- etldoc: osm_housenumber_point -> layer_housenumber:z14_
   SELECT osm_id, geometry, name, name_en, ele, ele_ft, rank
   FROM (
     SELECT osm_id, geometry, name, name_en,
     substring(ele from E'^(-?\\d+)(\\D|$)')::int AS ele,
     round(substring(ele from E'^(-?\\d+)(\\D|$)')::int*3.2808399) AS ele_ft,
       row_number() OVER (
           PARTITION BY LabelGrid(geometry, 100 * pixel_width)
           ORDER BY (
             substring(ele from E'^(-?\\d+)(\\D|$)')::int +
             (CASE WHEN length(NULLIF(wikipedia, '')) > 0 THEN 10000 ELSE 0 END) +
             (CASE WHEN length(NULLIF(name, '')) > 0 THEN 10000 ELSE 0 END)
           ) DESC
       )::int AS "rank"
     FROM osm_peak_point
     WHERE geometry && bbox AND ele is not null AND ele ~ E'^-?\\d+'
   ) AS ranked_peaks
   WHERE zoom_level >= 7 AND (rank <= 5 OR zoom_level >= 14)
   ORDER BY "rank" ASC;

$$ LANGUAGE SQL IMMUTABLE;
