CREATE OR REPLACE FUNCTION highway_is_link(highway TEXT) RETURNS BOOLEAN AS $$
    SELECT highway LIKE '%_link';
$$ LANGUAGE SQL IMMUTABLE STRICT;


-- etldoc: layer_transportation[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_transportation |<z4z7> z4-z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14_" ] ;
CREATE OR REPLACE FUNCTION layer_transportation(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text, subclass text, ramp int, oneway int, brunnel TEXT) AS $$
    SELECT
        osm_id, geometry,
        CASE
            WHEN highway <> '' THEN highway_class(highway)
            WHEN railway <> '' THEN railway_class(railway)
        END AS class,
        COALESCE(NULLIF(highway,''), NULLIF(railway, '')) AS subclass,
        -- All links are considered as ramps as well
        CASE WHEN highway_is_link(highway) THEN 1 ELSE is_ramp::int END AS ramp,
        is_oneway::int AS oneway,
        brunnel(is_bridge, is_tunnel, is_ford) AS brunnel
    FROM (
        -- etldoc: ne_10m_global_roads ->  layer_transportation:z4z6
        SELECT
            NULL::bigint AS osm_id, geometry,
            highway, NULL AS railway, NULL AS service,
            FALSE AS is_bridge, FALSE AS is_tunnel, FALSE AS is_ford,
            FALSE AS is_ramp, FALSE AS is_oneway,
            0 AS z_order
        FROM ne_10m_global_roads
        WHERE zoom_level BETWEEN 4 AND 6 AND scalerank <= 1 + zoom_level
        UNION ALL

        -- etldoc: osm_transportation_linestring_gen4  ->  layer_transportation:z7z8
        SELECT
            osm_id, geometry, highway, railway, service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_transportation_linestring_gen4
        WHERE zoom_level BETWEEN 7 AND 8
        UNION ALL

        -- etldoc: osm_transportation_linestring_gen3  ->  layer_transportation:z9
        SELECT
            osm_id, geometry, highway, railway, service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_transportation_linestring_gen3
        WHERE zoom_level = 9
        UNION ALL

        -- etldoc: osm_transportation_linestring_gen2  ->  layer_transportation:z10
        SELECT
            osm_id, geometry, highway, railway, service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_transportation_linestring_gen2
        WHERE zoom_level = 10
        UNION ALL

        -- etldoc: osm_transportation_linestring_gen1  ->  layer_transportation:z11
        SELECT
            osm_id, geometry, highway, railway, service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_transportation_linestring_gen1
        WHERE zoom_level = 11
        UNION ALL

        -- etldoc: osm_transportation_linestring       ->  layer_transportation:z12
        SELECT
            osm_id, geometry, highway, railway, service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_transportation_linestring
        WHERE zoom_level = 12
            AND (
                highway_class(highway) NOT IN ('track', 'path', 'minor')
                OR highway IN ('unclassified', 'residential')
            )
            AND NOT is_area
        UNION ALL

        -- etldoc: osm_transportation_linestring       ->  layer_transportation:z13
        SELECT osm_id, geometry, highway, railway, service, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_transportation_linestring
        WHERE zoom_level = 13
            AND (
                highway_class(highway) NOT IN ('track', 'path')
                OR (railway='rail' AND service = '')
            )
            AND NOT is_area
        UNION ALL

        -- etldoc: osm_transportation_linestring       ->  layer_transportation:z14_
        SELECT osm_id, geometry, highway, railway, service, is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_transportation_linestring
        WHERE zoom_level >= 14 AND NOT is_area
        UNION ALL

        -- NOTE: We limit the selection of polys because we need to be
        -- careful to net get false positives here because
        -- it is possible that closed linestrings appear both as
        -- highway linestrings and as polygon
        -- etldoc: osm_transportation__polygon          ->  layer_transportation:z13
        -- etldoc: osm_transportation__polygon          ->  layer_transportation:z14_
        SELECT
            osm_id, geometry,
            highway, NULL AS railway, NULL AS service,
            FALSE AS is_bridge, FALSE AS is_tunnel, FALSE AS is_ford,
            FALSE AS is_ramp, FALSE AS is_oneway, z_order
        FROM osm_transportation_polygon
        -- We do not want underground pedestrian areas for now
        WHERE zoom_level >= 13 AND is_area AND COALESCE(layer, 0) >= 0
    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;
