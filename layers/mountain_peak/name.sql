DO $$
BEGIN
  update osm_peak_point SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
END $$;
