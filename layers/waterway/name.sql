DO $$
BEGIN
  update osm_waterway_linestring SET tags = delete_empty_keys(tags) || get_basic_names(tags, geometry);
  update osm_waterway_linestring_gen1 SET tags = delete_empty_keys(tags) || get_basic_names(tags, geometry);
  update osm_waterway_linestring_gen2 SET tags = delete_empty_keys(tags) || get_basic_names(tags, geometry);
  update osm_waterway_linestring_gen3 SET tags = delete_empty_keys(tags) || get_basic_names(tags, geometry);
END $$;
