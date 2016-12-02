-- etldoc: layer_aeroway[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_aeroway |<z12> z12|<z13> z13|<z14> z14" ];

CREATE OR REPLACE FUNCTION layer_aeroway(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, class text) AS $$
    SELECT geometry, aeroway AS class FROM (
        -- etldoc:  aeroway_z12 -> layer_aeroway:z12
        SELECT geometry, aeroway
        FROM osm_aeroway_polygon_gen2 WHERE zoom_level = 12
        UNION ALL
        -- etldoc:  aeroway_z13 -> layer_aeroway:z13
        SELECT geometry, aeroway
        FROM osm_aeroway_polygon_gen1 WHERE zoom_level = 13
        UNION ALL
        -- etldoc:  aeroway_z14 -> layer_aeroway:z14_
        SELECT geometry, aeroway
        FROM osm_aeroway_polygon WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
