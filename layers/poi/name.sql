DO $$
BEGIN
  update osm_poi_point SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_poi_polygon SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
END $$;
