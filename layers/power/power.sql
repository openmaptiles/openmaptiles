-- etldoc: layer_power[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_power | <z13> z13 | <z14> z14+ " ] ;

CREATE OR REPLACE FUNCTION layer_power(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, class text, source text, method text, name text) AS $$
SELECT geometry, class, COALESCE(NULLIF(source, ''),NULLIF(gen_source, '')), method, name
FROM(
    -- etldoc: osm_power_point -> layer_power:z13
    SELECT geometry, class, source, gen_source, method, name
    FROM osm_power_point
    WHERE zoom_level >= 13 AND class = 'tower' AND geometry && bbox
    UNION ALL
    -- etldoc: osm_power_point -> layer_power:z14
    SELECT geometry, class, source, gen_source, method, name
    FROM osm_power_point
    WHERE zoom_level >= 14 AND class = 'pole' AND geometry && bbox
    UNION ALL
    -- etldoc: osm_power_linestring -> layer_power:z13
    SELECT geometry, class, source, gen_source,  method, name
    FROM osm_power_linestring
    WHERE zoom_level >= 13 AND class = 'line' AND geometry && bbox
    UNION ALL
    -- etldoc: osm_power_linestring -> layer_power:z14
    SELECT geometry, class, source, gen_source,  method, name
    FROM osm_power_linestring
    WHERE zoom_level >= 14 AND class = 'minor_line' AND geometry && bbox
    UNION ALL
    -- etldoc: osm_power_polygon -> layer_power:z13    
    SELECT geometry, class, source, gen_source, method, name
    FROM osm_power_polygon
    WHERE zoom_level >= 13 AND class = 'plant' AND geometry && bbox 
    UNION ALL
    -- etldoc: osm_power_polygon -> layer_power:z14
    SELECT geometry, class, source, gen_source, method, name
    FROM osm_power_polygon
    WHERE zoom_level >= 14 AND class IN ('substation', 'generator', 'transformer') AND geometry && bbox
    ) AS zoom_levels
WHERE geometry && bbox;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
