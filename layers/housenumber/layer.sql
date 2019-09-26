
-- etldoc: layer_housenumber[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_housenumber | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_housenumber(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, housenumber text) AS $$
   -- etldoc: osm_housenumber_point -> layer_housenumber:z14_
    SELECT osm_id, geometry, housenumber FROM osm_housenumber_point
    WHERE zoom_level >= 14 AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;
