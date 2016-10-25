CREATE OR REPLACE FUNCTION layer_highway_name(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, ref text, class highway_class, subclass text) AS $$
    SELECT osm_id, geometry, name, ref, to_highway_class(highway) AS class, highway AS subclass FROM (
        SELECT * FROM osm_highway_name_linestring_gen3
        WHERE zoom_level = 8
        UNION ALL
        SELECT * FROM osm_highway_name_linestring_gen2
        WHERE zoom_level = 9
        UNION ALL
        SELECT * FROM osm_highway_name_linestring_gen1
        WHERE zoom_level BETWEEN 10 AND 11
        UNION ALL
        SELECT * FROM osm_highway_name_linestring
        WHERE zoom_level = 12
            AND to_highway_class(highway) < 'minor_road'::highway_class
            AND NOT highway_is_link(highway)
        UNION ALL
        SELECT * FROM osm_highway_name_linestring
        WHERE zoom_level = 13
            AND to_highway_class(highway) < 'path'::highway_class
        UNION ALL
        SELECT * FROM osm_highway_name_linestring
        WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox AND LineLabel(zoom_level, COALESCE(NULLIF(name, ''), ref), geometry)
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;
