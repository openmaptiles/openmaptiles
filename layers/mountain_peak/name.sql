DO $$
BEGIN
  update osm_peak_point SET tags = slice_language_tags(tags) || hstore(ARRAY[
      'name:latin', get_latin_name(tags),
      'name:nonlatin', get_nonlatin_name(tags),
      'name_int', get_name_int(tags)
  ]);
END $$;
