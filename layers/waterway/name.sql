DO $$
BEGIN
  update osm_waterway_linestring SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
END $$;
