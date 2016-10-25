CREATE OR REPLACE FUNCTION highway_is_link(highway TEXT) RETURNS BOOLEAN AS $$
    SELECT highway LIKE '%_link';
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION layer_highway(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class highway_class, subclass text, properties highway_properties) AS $$
    SELECT
		osm_id, geometry,
		to_highway_class(highway) AS class, highway AS subclass,
		to_highway_properties(is_bridge, is_tunnel, is_ford, is_ramp, is_oneway) AS properties
	FROM (
		SELECT
			NULL::bigint AS osm_id, geometry, highway,
			FALSE AS is_bridge, FALSE AS is_tunnel, FALSE AS is_ford, FALSE AS is_ramp, FALSE AS is_oneway,
			0 AS z_order
		FROM ne_10m_global_roads
		WHERE zoom_level BETWEEN 4 AND 7 AND scalerank <= 1 + zoom_level
		UNION ALL
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring_gen4
		WHERE zoom_level = 8
		UNION ALL
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring_gen3
		WHERE zoom_level = 9
		UNION ALL
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring_gen2
		WHERE zoom_level = 10
		UNION ALL
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring_gen1
		WHERE zoom_level = 11
		UNION ALL
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring
		WHERE zoom_level = 12 AND to_highway_class(highway) < 'minor_road'::highway_class AND NOT highway_is_link(highway)
        UNION ALL
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring
		WHERE zoom_level = 13 AND to_highway_class(highway) < 'path'::highway_class
        UNION ALL
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring
		WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;
