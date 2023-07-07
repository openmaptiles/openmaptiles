CREATE OR REPLACE FUNCTION display_housenumber(raw_housenumber text)
RETURNS text AS $$
DECLARE
  min_number int;
  max_number int;
BEGIN
  -- Check if the input string contains a semi-colon separator
  IF raw_housenumber !~ ';' THEN
    RETURN raw_housenumber;
  END IF;

  -- Find the minimum and maximum numbers in the list
  SELECT MIN(value), MAX(value) INTO min_number, max_number
  FROM unnest(string_to_array(raw_housenumber, ';')::int[]) AS value;

  -- Return the consolidated range string
  RETURN min_number::text || '–' || max_number::text;
END;
$$ LANGUAGE plpgsql;
