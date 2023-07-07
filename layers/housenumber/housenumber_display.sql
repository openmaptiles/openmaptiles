CREATE OR REPLACE FUNCTION display_housenumber(raw_housenumber text)
RETURNS text AS $$
DECLARE
  numbers_arr int[];
  min_number int;
  max_number int;
  consolidated_range text;
BEGIN
  -- Check if the input string contains a semi-colon separator
  IF raw_housenumber !~ ';' THEN
    RETURN raw_housenumber;
  END IF;

  -- Convert the input string into an array of integers
  numbers_arr := string_to_array(raw_housenumber, ';')::int[];

  -- Find the minimum and maximum numbers in the array
  SELECT MIN(value), MAX(value) INTO min_number, max_number
  FROM unnest(numbers_arr) AS value;

  -- Build the consolidated range string
  consolidated_range := min_number::text || '–' || max_number::text;

  -- Return the consolidated range string
  RETURN consolidated_range;
END;
$$ LANGUAGE plpgsql;
