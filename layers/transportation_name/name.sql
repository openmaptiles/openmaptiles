DO $$
BEGIN
  update osm_highway_linestring SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_railway_linestring SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_aerialway_linestring SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_shipway_linestring SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
END $$;
