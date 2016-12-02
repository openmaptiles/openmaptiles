-- etldoc: layer_building[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_building | <z13> z13 | <z14_> z14_ " ] ;

CREATE OR REPLACE FUNCTION layer_building(bbox geometry, zoom_level int)
RETURNS TABLE(geom geometry, render_height int, render_min_height int) AS $$
    SELECT geometry, render_height, render_min_height
    FROM (
        -- etldoc: osm_building_polygon_gen1 -> layer_building:z13
        SELECT
            geometry,
            NULL::int AS render_height, NULL::int AS render_min_height
        FROM osm_buildings_large
        WHERE zoom_level = 13 AND geometry && bbox AND ST_Area(geometry) > 1400
        UNION ALL
        -- etldoc: osm_building_polygon -> layer_building:z14_
        SELECT
            geometry,
            greatest(5, COALESCE(height, levels*3.66,5))::int AS render_height,
            greatest(0, COALESCE(min_height, min_level*3.66,0))::int AS render_min_height
        FROM osm_building_polygon
        WHERE zoom_level >= 14 AND geometry && bbox
    ) AS zoom_levels
    ORDER BY render_height ASC, ST_YMin(geometry) DESC;
$$ LANGUAGE SQL IMMUTABLE;
