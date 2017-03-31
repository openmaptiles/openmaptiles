CREATE OR REPLACE FUNCTION highway_is_link(highway TEXT) RETURNS BOOLEAN AS $$
    SELECT highway LIKE '%_link';
$$ LANGUAGE SQL IMMUTABLE STRICT;


-- etldoc: layer_transportation[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_transportation |<z4> z4 |<z5> z5 |<z6> z6 |<z7> z7 |<z8> z8 |<z9z10> z9-z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;
CREATE OR REPLACE FUNCTION layer_transportation(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text, ramp int, oneway int, brunnel TEXT, service TEXT) AS $$
    SELECT
        osm_id, geometry,
        CASE
            WHEN highway IS NOT NULL THEN highway_class(highway)
            WHEN railway IS NOT NULL THEN railway_class(railway)
        END AS class,
        -- All links are considered as ramps as well
        CASE WHEN highway_is_link(highway) OR highway = 'steps'
             THEN 1 ELSE is_ramp::int END AS ramp,
        is_oneway::int AS oneway,
        brunnel(is_bridge, is_tunnel, is_ford) AS brunnel,
        NULLIF(service, '') AS service
    FROM (
        -- etldoc: osm_transportation_merge_linestring_gen7 -> layer_transportation:z4
        SELECT
            osm_id, geometry, highway, NULL AS railway, NULL AS service,
            NULL::boolean AS is_bridge, NULL::boolean AS is_tunnel,
            NULL::boolean AS is_ford,
            NULL::boolean AS is_ramp, NULL::boolean AS is_oneway,
            z_order
        FROM osm_transportation_merge_linestring_gen7
        WHERE zoom_level = 4
        UNION ALL

        -- etldoc: osm_transportation_merge_linestring_gen6 -> layer_transportation:z5
        SELECT
            osm_id, geometry, highway, NULL AS railway, NULL AS service,
            NULL::boolean AS is_bridge, NULL::boolean AS is_tunnel,
            NULL::boolean AS is_ford,
            NULL::boolean AS is_ramp, NULL::boolean AS is_oneway,
            z_order
        FROM osm_transportation_merge_linestring_gen6
        WHERE zoom_level = 5
        UNION ALL

        -- etldoc: osm_transportation_merge_linestring_gen5 -> layer_transportation:z6
        SELECT
            osm_id, geometry, highway, NULL AS railway, NULL AS service,
            NULL::boolean AS is_bridge, NULL::boolean AS is_tunnel,
            NULL::boolean AS is_ford,
            NULL::boolean AS is_ramp, NULL::boolean AS is_oneway,
            z_order
        FROM osm_transportation_merge_linestring_gen5
        WHERE zoom_level = 6
        UNION ALL

        -- etldoc: osm_transportation_merge_linestring_gen4  ->  layer_transportation:z7
        SELECT
            osm_id, geometry, highway, NULL AS railway, NULL AS service,
            NULL::boolean AS is_bridge, NULL::boolean AS is_tunnel,
            NULL::boolean AS is_ford,
            NULL::boolean AS is_ramp, NULL::boolean AS is_oneway,
            z_order
        FROM osm_transportation_merge_linestring_gen4
        WHERE zoom_level = 7
        UNION ALL

        -- etldoc: osm_transportation_merge_linestring_gen3  ->  layer_transportation:z8
        SELECT
            osm_id, geometry, highway, NULL AS railway, NULL AS service,
            NULL::boolean AS is_bridge, NULL::boolean AS is_tunnel,
            NULL::boolean AS is_ford,
            NULL::boolean AS is_ramp, NULL::boolean AS is_oneway,
            z_order
        FROM osm_transportation_merge_linestring_gen3
        WHERE zoom_level = 8
        UNION ALL

        -- etldoc: osm_highway_linestring_gen2  ->  layer_transportation:z9z10
        SELECT
            osm_id, geometry, highway, NULL AS railway, NULL AS service,
            NULL::boolean AS is_bridge, NULL::boolean AS is_tunnel,
            NULL::boolean AS is_ford,
            NULL::boolean AS is_ramp, NULL::boolean AS is_oneway,
            z_order
        FROM osm_highway_linestring_gen2
        WHERE zoom_level BETWEEN 9 AND 10
        UNION ALL

        -- etldoc: osm_highway_linestring_gen1  ->  layer_transportation:z11
        SELECT
            osm_id, geometry, highway, NULL AS railway, NULL AS service,
            NULL::boolean AS is_bridge, NULL::boolean AS is_tunnel,
            NULL::boolean AS is_ford,
            NULL::boolean AS is_ramp, NULL::boolean AS is_oneway,
            z_order
        FROM osm_highway_linestring_gen1
        WHERE zoom_level = 11
        UNION ALL

        -- etldoc: osm_highway_linestring       ->  layer_transportation:z12
        -- etldoc: osm_highway_linestring       ->  layer_transportation:z13
        -- etldoc: osm_highway_linestring       ->  layer_transportation:z14_
        SELECT
            osm_id, geometry, highway, NULL AS railway,
            service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_highway_linestring
        WHERE NOT is_area AND (
            zoom_level = 12 AND (
                highway_class(highway) NOT IN ('track', 'path', 'minor')
                OR highway IN ('unclassified', 'residential')
            )
            OR zoom_level = 13 AND highway_class(highway) NOT IN ('track', 'path')
            OR zoom_level >= 14
        )
        UNION ALL

        -- etldoc: osm_railway_linestring_gen2  ->  layer_transportation:z11
        SELECT
            osm_id, geometry, NULL AS highway, railway,
            service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_railway_linestring_gen2
        WHERE zoom_level = 11 AND (railway='rail' AND service = '')
        UNION ALL

        -- etldoc: osm_railway_linestring_gen1  ->  layer_transportation:z12
        SELECT
            osm_id, geometry, NULL AS highway, railway,
            service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_railway_linestring_gen1
        WHERE zoom_level = 12 AND (railway='rail' AND service = '')
        UNION ALL

        -- etldoc: osm_railway_linestring       ->  layer_transportation:z13
        -- etldoc: osm_railway_linestring       ->  layer_transportation:z14_
        SELECT
            osm_id, geometry, NULL AS highway, railway,
            service_value(service) AS service,
            is_bridge, is_tunnel, is_ford, is_ramp, is_oneway, z_order
        FROM osm_railway_linestring
        WHERE zoom_level = 13 AND (railway='rail' AND service = '')
           OR zoom_Level >= 14
        UNION ALL

        -- NOTE: We limit the selection of polys because we need to be
        -- careful to net get false positives here because
        -- it is possible that closed linestrings appear both as
        -- highway linestrings and as polygon
        -- etldoc: osm_highway_polygon          ->  layer_transportation:z13
        -- etldoc: osm_highway_polygon          ->  layer_transportation:z14_
        SELECT
            osm_id, geometry,
            highway, NULL AS railway, NULL AS service,
            FALSE AS is_bridge, FALSE AS is_tunnel, FALSE AS is_ford,
            FALSE AS is_ramp, FALSE AS is_oneway, z_order
        FROM osm_highway_polygon
        -- We do not want underground pedestrian areas for now
        WHERE zoom_level >= 13 AND is_area AND COALESCE(layer, 0) >= 0
    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;
