CREATE OR REPLACE FUNCTION layer_poi(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, class text, subclass text) AS $$
    SELECT id, geometry, name, NULLIF(name_en, ''), poi_class(subclass) AS class, subclass
    FROM osm_poi_point
    WHERE geometry && bbox
      AND name <> ''
      AND (zoom_level >= 14);
$$ LANGUAGE SQL IMMUTABLE;
