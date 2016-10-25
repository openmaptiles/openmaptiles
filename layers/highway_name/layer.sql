CREATE OR REPLACE FUNCTION layer_highway_name(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, class highway_class, subclass text) AS $$
    SELECT osm_id, geometry, name, to_highway_class(highway) AS class, highway AS subclass FROM (
        SELECT * FROM osm_highway_name_linestring
        WHERE zoom_level = 12 AND to_highway_class(highway) < 'minor_road'::highway_class AND NOT highway_is_link(highway)
        UNION ALL
        SELECT * FROM osm_highway_name_linestring
        WHERE zoom_level = 13 AND to_highway_class(highway) < 'path'::highway_class
        UNION ALL
        SELECT * FROM osm_highway_name_linestring
        WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;
