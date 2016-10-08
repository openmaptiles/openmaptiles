CREATE OR REPLACE VIEW building_z13 AS (
    SELECT osm_id, way, height, levels FROM buildings WHERE way_area > 1400
);

CREATE OR REPLACE VIEW building_z14 AS (
    SELECT osm_id, way, height, levels FROM buildings
);

CREATE OR REPLACE FUNCTION layer_building(bbox geometry, zoom_level int)
RETURNS TABLE(geom geometry, osm_id bigint, render_height float) AS $$
    WITH zoom_levels AS (
        SELECT osm_id, ST_Simplify(way, 10) AS way, height, levels FROM building_z13
        WHERE zoom_level = 13
        UNION ALL
        SELECT * FROM building_z14
        WHERE zoom_level >= 14
    )
    SELECT way, osm_id,
    least(greatest(3, COALESCE(height, levels*3.66,5)),400)^.7 AS render_height
    FROM zoom_levels
    WHERE way && bbox
    ORDER BY render_height, ST_YMin(way) DESC;
$$ LANGUAGE SQL IMMUTABLE;

