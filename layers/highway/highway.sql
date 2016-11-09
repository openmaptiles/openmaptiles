 

CREATE OR REPLACE FUNCTION highway_is_link(highway TEXT) RETURNS BOOLEAN AS $$
    SELECT highway LIKE '%_link';
$$ LANGUAGE SQL IMMUTABLE STRICT;


-- etldoc: layer_highway[shape=record fillcolor=lightpink, style="rounded,filled",  
-- etldoc:     label="<sql> layer_highway |<z4z7> z4-z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14_" ] ;
CREATE OR REPLACE FUNCTION layer_highway(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class highway_class, subclass text, properties highway_properties) AS $$
    SELECT
		osm_id, geometry,
		to_highway_class(highway) AS class, highway AS subclass,
		to_highway_properties(is_bridge, is_tunnel, is_ford, is_ramp, is_oneway) AS properties
	FROM (

		-- etldoc: ne_10m_global_roads ->  layer_highway:z4z7
		SELECT 
			NULL::bigint AS osm_id, geometry, highway,
			FALSE AS is_bridge, FALSE AS is_tunnel, FALSE AS is_ford, FALSE AS is_ramp, FALSE AS is_oneway,
			0 AS z_order
		FROM ne_10m_global_roads
		WHERE zoom_level BETWEEN 4 AND 7 AND scalerank <= 1 + zoom_level
		UNION ALL

		-- etldoc: osm_highway_linestring_gen4  ->  layer_highway:z8
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring_gen4
		WHERE zoom_level = 8
		UNION ALL

		-- etldoc: osm_highway_linestring_gen3  ->  layer_highway:z9
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring_gen3
		WHERE zoom_level = 9
		UNION ALL

		-- etldoc: osm_highway_linestring_gen2  ->  layer_highway:z10
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring_gen2
		WHERE zoom_level = 10
		UNION ALL

		-- etldoc: osm_highway_linestring_gen1  ->  layer_highway:z11
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring_gen1
		WHERE zoom_level = 11
		UNION ALL

		-- etldoc: osm_highway_linestring       ->  layer_highway:z12
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring
		WHERE zoom_level = 12
            AND (to_highway_class(highway) < 'minor_road'::highway_class OR highway IN ('unclassified', 'residential'))
            AND NOT highway_is_link(highway)
            AND NOT is_area
        UNION ALL

		-- etldoc: osm_highway_linestring       ->  layer_highway:z13
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring
		WHERE zoom_level = 13
            AND to_highway_class(highway) < 'path'::highway_class
            AND NOT is_area
        UNION ALL

		-- etldoc: osm_highway_linestring       ->  layer_highway:z14_
		SELECT osm_id, geometry, highway, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring
		WHERE zoom_level >= 14 AND NOT is_area
        UNION ALL

        -- NOTE: We limit the selection of polys because we need to be careful to net get false positives here because
        -- it is possible that closed linestrings appear both as highway linestrings and as polygon
        -- etldoc: osm_highway_polygon          ->  layer_highway:z13
        -- etldoc: osm_highway_polygon          ->  layer_highway:z14_
		SELECT osm_id, geometry, highway, FALSE AS is_bridge, FALSE AS is_tunnel, FALSE AS is_ford, FALSE AS is_ramp, FALSE AS is_oneway, z_order
        FROM osm_highway_polygon
        -- We do not want underground pedestrian areas for now
		WHERE zoom_level BETWEEN 13 AND 14 AND is_area AND COALESCE(layer, 0) >= 0
    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;
