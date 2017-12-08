
-- etldoc: layer_housenumber[shape=record fillcolor=lightpink, style="rounded,filled",  
-- etldoc:     label="layer_housenumber | <z15_> z15+" ] ;

CREATE OR REPLACE FUNCTION layer_housenumber(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, housenumber text) AS $$
   -- etldoc: osm_housenumber_point -> layer_housenumber:z15_
    SELECT osm_id, geometry, housenumber FROM osm_housenumber_point
    WHERE zoom_level >= 15 AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
