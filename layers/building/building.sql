-- etldoc: layer_building[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_building | <z13> z13 | <z14_> z14+ " ] ;

CREATE OR REPLACE FUNCTION as_numeric(text) RETURNS NUMERIC AS $$
 -- Inspired by http://stackoverflow.com/questions/16195986/isnumeric-with-postgresql/16206123#16206123
DECLARE test NUMERIC;
BEGIN
     test = $1::NUMERIC;
     RETURN test;
EXCEPTION WHEN others THEN
     RETURN -1;
END;
$$ STRICT
LANGUAGE plpgsql IMMUTABLE;

CREATE MATERIALIZED VIEW all_buildings AS (
        SELECT * FROM (
	SELECT
        obp.osm_id,
           COALESCE(obp.geometry,obpm.geometry) AS geometry,
     greatest(as_numeric(obp.height),as_numeric(obpm.height),as_numeric(obpm.buildingheight),as_numeric(obpm.relheight),as_numeric(obpm.relbuildingheight)) AS height, 
     greatest(as_numeric(obp.min_height),as_numeric(obpm.min_height),as_numeric(obpm.buildingmin_height),as_numeric(obpm.relmin_height),as_numeric(obpm.relbuildingmin_height)) AS min_height,
     greatest(as_numeric(obp.levels),as_numeric(obpm.levels),as_numeric(obpm.buildinglevels),as_numeric(obpm.rellevels),as_numeric(obpm.relbuildinglevels)) AS levels,
     greatest(as_numeric(obp.min_level),as_numeric(obpm.min_level),as_numeric(obpm.buildingmin_level),as_numeric(obpm.relmin_level),as_numeric(obpm.relbuildingmin_level)) AS min_level,
           COALESCE(obpm.role, '') AS role,
           obpm.member AS member
        FROM osm_building_polygon AS obp
        FULL OUTER JOIN 
        osm_building_polygon_member AS obpm
        ON obp.osm_id = obpm.member
) AS joined
 WHERE role <> 'outline');
CREATE INDEX IF NOT EXISTS osm_all_buildings_geometry_idx ON all_buildings USING gist(geometry);

CREATE OR REPLACE FUNCTION layer_building(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, osm_id bigint, render_height int, render_min_height int) AS $$
    SELECT geometry, osm_id, render_height, render_min_height
    FROM (
        -- etldoc: osm_building_polygon_gen1 -> layer_building:z13
        SELECT
            osm_id, geometry,
            NULL::int AS render_height, NULL::int AS render_min_height
        FROM osm_building_polygon_gen1
        WHERE zoom_level = 13 AND geometry && bbox AND area > 1400
        UNION ALL
        -- etldoc: osm_building_polygon -> layer_building:z14_
        SELECT
           osm_id, geometry,
           ceil(greatest(5, COALESCE(height, levels*3.66,5)))::int AS render_height,
           floor(greatest(0, COALESCE(min_height, min_level*3.66,0)))::int AS render_min_height FROM
        all_buildings
        WHERE zoom_level >= 14 AND geometry && bbox
    ) AS zoom_levels
    ORDER BY render_height ASC, ST_YMin(geometry) DESC;
$$ LANGUAGE SQL IMMUTABLE;
