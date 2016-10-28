CREATE OR REPLACE FUNCTION layer_poi(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, class text, subclass text, gridrank bigint) AS $$
    SELECT id, geometry, name, NULLIF(name_en, ''), poi_class(subclass) AS class, subclass,
        row_number() OVER (
            PARTITION BY LabelGrid(geometry, 100 * pixel_width)
            ORDER BY poi_class_rank(poi_class(subclass)) ASC, length(name) DESC
        ) AS gridrank
    FROM osm_poi_point
    WHERE geometry && bbox
      AND zoom_level >= 14
      AND name <> ''
    ORDER BY gridrank;
$$ LANGUAGE SQL IMMUTABLE;
