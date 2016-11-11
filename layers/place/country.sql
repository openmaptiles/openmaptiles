
-- etldoc: layer_country[shape=record fillcolor=lightpink, style="rounded,filled",  
-- etldoc:     label="layer_country | <zall> z0-z14_ " ] ;

-- etldoc: osm_country_point -> layer_country
CREATE OR REPLACE FUNCTION layer_country(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, "rank" int) AS $$
    SELECT osm_id, geometry, name, COALESCE(NULLIF(name_en, ''), name) AS name_en, "rank" FROM osm_country_point
    WHERE geometry && bbox AND "rank" <= zoom_level AND name <> ''
    ORDER BY "rank" ASC, length(name) ASC;
$$ LANGUAGE SQL IMMUTABLE;
