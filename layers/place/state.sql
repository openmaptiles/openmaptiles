
-- etldoc: layer_state[shape=record fillcolor=lightpink, style="rounded,filled",  
-- etldoc:     label="layer_state | <zall> z0-z14_ " ] ;

-- etldoc:  osm_state_point -> layer_state

CREATE OR REPLACE FUNCTION layer_state(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, "rank" int) AS $$
    SELECT osm_id, geometry, name, COALESCE(NULLIF(name_en, ''), name) AS name_en, "rank"
    FROM osm_state_point
    WHERE geometry && bbox AND
          name <> '' AND
          ("rank" + 2 <= zoom_level) AND (
              zoom_level >= 5 OR
              is_in_country IN ('United Kingdom', 'USA', 'Россия', 'Brasil', 'China', 'India') OR
              is_in_country_code IN ('AU', 'CN', 'IN', 'BR', 'US'))
    ORDER BY "rank" ASC;
$$ LANGUAGE SQL IMMUTABLE;
