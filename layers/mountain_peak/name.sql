CREATE OR REPLACE FUNCTION get_latin_name(tags hstore) RETURNS text AS $$
    SELECT COALESCE(
      NULLIF(tags->'name:en', ''),
      NULLIF(tags->'int_name', ''),
      CASE
        WHEN tags->'name' ~ '.*[a-zA-Z].*'
          THEN tags->'name'
        ELSE NULL
      END
    );
$$ LANGUAGE SQL IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION get_nonlatin_name(tags hstore) RETURNS text AS $$
    SELECT
      CASE
        WHEN tags->'name' !~ '.*[a-zA-Z].*'
          THEN tags->'name'
        ELSE NULL
      END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION get_name_int(tags hstore) RETURNS text AS $$
    SELECT
      COALESCE(
        NULLIF(tags->'int_name', ''),
        NULLIF(tags->'name:en', ''),
        tags->'name'
      );
$$ LANGUAGE SQL IMMUTABLE STRICT;


DO $$
BEGIN
  update osm_peak_point SET tags = tags || hstore(ARRAY[
      'name:latin', get_latin_name(tags),
      'name:nonlatin', get_nonlatin_name(tags),
      'name_int', get_name_int(tags)
  ]);
END $$;
