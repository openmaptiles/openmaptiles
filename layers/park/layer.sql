-- etldoc: layer_park[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_park |<z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_park(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text) AS $$
    SELECT osm_id, geometry,
        COALESCE(NULLIF(boundary, ''), NULLIF(leisure, '')) AS class
        FROM (
        -- etldoc: osm_park_polygon_gen8 -> layer_park:z6
        SELECT osm_id, geometry, leisure, boundary, NULL::int as scalerank
        FROM osm_park_polygon_gen8
        WHERE zoom_level = 6
        UNION ALL
        -- etldoc: osm_park_polygon_gen7 -> layer_park:z7
        SELECT osm_id, geometry, leisure, boundary, NULL::int as scalerank
        FROM osm_park_polygon_gen7
        WHERE zoom_level = 7
        UNION ALL
        -- etldoc: osm_park_polygon_gen6 -> layer_park:z8
        SELECT osm_id, geometry, leisure, boundary, NULL::int as scalerank
        FROM osm_park_polygon_gen6
        WHERE zoom_level = 8
        UNION ALL
        -- etldoc: osm_park_polygon_gen5 -> layer_park:z9
        SELECT osm_id, geometry, leisure, boundary, NULL::int as scalerank
        FROM osm_park_polygon_gen5
        WHERE zoom_level = 9
        UNION ALL
        -- etldoc: osm_park_polygon_gen4 -> layer_park:z10
        SELECT osm_id, geometry, leisure, boundary, NULL::int as scalerank
        FROM osm_park_polygon_gen4
        WHERE zoom_level = 10
        UNION ALL
        -- etldoc: osm_park_polygon_gen3 -> layer_park:z11
        SELECT osm_id, geometry, leisure, boundary, NULL::int as scalerank
        FROM osm_park_polygon_gen3
        WHERE zoom_level = 11
        UNION ALL
        -- etldoc: osm_park_polygon_gen2 -> layer_park:z12
        SELECT osm_id, geometry, leisure, boundary, NULL::int as scalerank
        FROM osm_park_polygon_gen2
        WHERE zoom_level = 12
        UNION ALL
        -- etldoc: osm_park_polygon_gen1 -> layer_park:z13
        SELECT osm_id, geometry, leisure, boundary, NULL::int as scalerank
        FROM osm_park_polygon_gen1
        WHERE zoom_level = 13
        UNION ALL
        -- etldoc: osm_park_polygon -> layer_park:z14
        SELECT osm_id, geometry, leisure, boundary, NULL::int as scalerank
        FROM osm_park_polygon
        WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
