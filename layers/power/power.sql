
-- CREATE OR REPLACE FUNCTION layer_power(bbox geometry, zoom_level int)
-- RETURNS TABLE(geometry geometry, class text, source text, method text, name text) AS $$
-- SELECT geometry, class, source, method, name
-- FROM(
    -- SELECT geometry, class, source, method, name
    -- FROM osm_power_point
    -- WHERE zoom_level >= 10 AND geometry && bbox
    -- UNION ALL
    
    -- SELECT geometry, class, source, method, name
    -- FROM osm_power_linestring
    -- WHERE zoom_level >= 10 AND geometry && bbox
    -- UNION ALL
    
    -- SELECT geometry, class, source, method, name
    -- FROM osm_power_polygon
    -- WHERE zoom_level >= 10 AND geometry && bbox 
    -- ) AS zoom_levels
-- WHERE geometry && bbox;
-- $$ LANGUAGE SQL STABLE
                -- -- STRICT
                -- PARALLEL SAFE;

CREATE OR REPLACE FUNCTION layer_power(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, name text, class text) AS $$
SELECT geometry, name, class
FROM(
    SELECT geometry, name, class
    FROM osm_power_point
    WHERE zoom_level >= 10 AND geometry && bbox
    UNION ALL
    
    SELECT geometry, name, class
    FROM osm_power_linestring
    WHERE zoom_level >= 10 AND geometry && bbox
    UNION ALL
    
    SELECT geometry, name, class
    FROM osm_power_polygon
    WHERE zoom_level >= 10 AND geometry && bbox 
    ) AS zoom_levels
WHERE geometry && bbox;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
