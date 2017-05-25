UPDATE osm_poi_point
  SET subclass = 'subway'
  WHERE station = 'subway' and subclass='station';
UPDATE osm_poi_polygon
  SET subclass = 'subway'
  WHERE station = 'subway' and subclass='station';
