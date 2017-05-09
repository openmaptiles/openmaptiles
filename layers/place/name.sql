DO $$
BEGIN
  update osm_continent_point SET tags = tags || hstore(ARRAY[
      'name:latin', get_latin_name(tags),
      'name:nonlatin', get_nonlatin_name(tags),
      'name_int', get_name_int(tags)
  ]);
  update osm_country_point SET tags = tags || hstore(ARRAY[
      'name:latin', get_latin_name(tags),
      'name:nonlatin', get_nonlatin_name(tags),
      'name_int', get_name_int(tags)
  ]);
  update osm_island_polygon SET tags = tags || hstore(ARRAY[
      'name:latin', get_latin_name(tags),
      'name:nonlatin', get_nonlatin_name(tags),
      'name_int', get_name_int(tags)
  ]);
  update osm_island_point SET tags = tags || hstore(ARRAY[
      'name:latin', get_latin_name(tags),
      'name:nonlatin', get_nonlatin_name(tags),
      'name_int', get_name_int(tags)
  ]);
  update osm_state_point SET tags = tags || hstore(ARRAY[
      'name:latin', get_latin_name(tags),
      'name:nonlatin', get_nonlatin_name(tags),
      'name_int', get_name_int(tags)
  ]);
  update osm_city_point SET tags = tags || hstore(ARRAY[
      'name:latin', get_latin_name(tags),
      'name:nonlatin', get_nonlatin_name(tags),
      'name_int', get_name_int(tags)
  ]);
END $$;
