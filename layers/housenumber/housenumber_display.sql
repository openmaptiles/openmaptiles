CREATE OR REPLACE FUNCTION display_housenumber_nonnumeric(raw_housenumber text)
RETURNS text AS $$
  -- Find the position of the semicolon in the input string
  -- and extract the first and last value
  SELECT substring(raw_housenumber from 1 for position(';' in raw_housenumber) - 1)
         || '–'
         || substring(raw_housenumber from position(';' in raw_housenumber) + 1);
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION display_housenumber(raw_housenumber text)
RETURNS text AS $$
  SELECT CASE
    WHEN raw_housenumber !~ ';' THEN raw_housenumber
    WHEN raw_housenumber ~ '[^0-9;]' THEN display_housenumber_nonnumeric(raw_housenumber)
    ELSE
      (SELECT min(value)::text || '–' || max(value)::text
       FROM unnest(string_to_array(raw_housenumber, ';')::int[]) AS value)
  END
$$ LANGUAGE SQL IMMUTABLE;
