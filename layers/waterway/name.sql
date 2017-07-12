DO $$
BEGIN
  update osm_waterway_linestring SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_waterway_linestring_gen1 SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_waterway_linestring_gen2 SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_waterway_linestring_gen3 SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
END $$;
