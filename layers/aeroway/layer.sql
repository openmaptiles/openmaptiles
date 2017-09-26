-- etldoc: layer_aeroway[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_aeroway |<z10> z10|<z11> z11|<z12> z12|<z13> z13|<z14_> z14+" ];

CREATE OR REPLACE FUNCTION layer_aeroway(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, class text, ref text) AS $$
    SELECT geometry, aeroway AS class, ref FROM (
        -- etldoc:  osm_aeroway_linestring_gen3 -> layer_aeroway:z10
        SELECT geometry, aeroway, ref
        FROM osm_aeroway_linestring_gen3 WHERE zoom_level = 10
        UNION ALL
        -- etldoc:  osm_aeroway_linestring_gen2 -> layer_aeroway:z11
        SELECT geometry, aeroway, ref
        FROM osm_aeroway_linestring_gen2 WHERE zoom_level = 11
        UNION ALL
        -- etldoc:  osm_aeroway_linestring_gen1 -> layer_aeroway:z12
        SELECT geometry, aeroway, ref
        FROM osm_aeroway_linestring_gen1 WHERE zoom_level = 12
        UNION ALL
        -- etldoc:  osm_aeroway_linestring -> layer_aeroway:z13
        -- etldoc:  osm_aeroway_linestring -> layer_aeroway:z14_
        SELECT geometry, aeroway, ref
        FROM osm_aeroway_linestring WHERE zoom_level >= 13
        UNION ALL

        -- etldoc:  osm_aeroway_polygon_gen3 -> layer_aeroway:z10
        -- etldoc:  osm_aeroway_polygon_gen3 -> layer_aeroway:z11
        SELECT geometry, aeroway, ref
        FROM osm_aeroway_polygon_gen3 WHERE zoom_level BETWEEN 10 AND 11
        UNION ALL
        -- etldoc:  osm_aeroway_polygon_gen2 -> layer_aeroway:z12
        SELECT geometry, aeroway, ref
        FROM osm_aeroway_polygon_gen2 WHERE zoom_level = 12
        UNION ALL
        -- etldoc:  osm_aeroway_polygon_gen1 -> layer_aeroway:z13
        SELECT geometry, aeroway, ref
        FROM osm_aeroway_polygon_gen1 WHERE zoom_level = 13
        UNION ALL
        -- etldoc:  osm_aeroway_polygon -> layer_aeroway:z14_
        SELECT geometry, aeroway, ref
        FROM osm_aeroway_polygon WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
