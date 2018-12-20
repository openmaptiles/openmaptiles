
-- etldoc: layer_tree[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_tree | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_tree(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry) AS $$
   -- etldoc: osm_tree -> layer_tree:z14_
   SELECT osm_id, geometry
   FROM osm_tree
   WHERE zoom_level >= 14 AND geometry && bbox;

$$ LANGUAGE SQL IMMUTABLE;
