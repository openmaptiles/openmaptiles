DO $$
BEGIN
  update osm_marine_point SET tags = tags || hstore(ARRAY[
      'name:latin', get_latin_name(tags),
      'name:nonlatin', get_nonlatin_name(tags),
      'name_int', get_name_int(tags)
  ]);
  update osm_water_polygon SET tags = tags || hstore(ARRAY[
      'name:latin', get_latin_name(tags),
      'name:nonlatin', get_nonlatin_name(tags),
      'name_int', get_name_int(tags)
  ]);
END $$;
