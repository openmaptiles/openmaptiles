DO $$
BEGIN
  update osm_marine_point SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_water_polygon SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
END $$;
