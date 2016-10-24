CREATE OR REPLACE VIEW building_z13 AS (
    SELECT osm_id, geometry, height, levels FROM osm_building_polygon_gen1 WHERE area > 1400
);

CREATE OR REPLACE VIEW building_z14 AS (
    SELECT osm_id, geometry, height, levels FROM osm_building_polygon
);

CREATE OR REPLACE FUNCTION layer_building(bbox geometry, zoom_level int)
RETURNS TABLE(geom geometry, osm_id bigint, render_height numeric) AS $$
    SELECT geometry, osm_id,
    least(greatest(3, COALESCE(height, levels*3.66,5)),400)^.7::int AS render_height
    FROM (
        SELECT osm_id, ST_Simplify(geometry, 10) AS geometry, height, levels FROM building_z13
        WHERE zoom_level = 13 AND geometry && bbox
        UNION ALL
        SELECT * FROM building_z14
        WHERE zoom_level >= 14 AND geometry && bbox
    ) AS zoom_levels
    ORDER BY render_height ASC, ST_YMin(geometry) DESC;
$$ LANGUAGE SQL IMMUTABLE;

