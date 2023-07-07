CREATE OR REPLACE FUNCTION display_housenumber_nonnumeric(raw_housenumber text)
RETURNS text AS $$
DECLARE
  arr text[];
BEGIN
  -- Convert the input string into an array of values
  arr := string_to_array(raw_housenumber, ';')::text[];

  -- Return the first and last value in the array
  RETURN arr[1] || '–' || arr[array_length(arr, 1)];
END;
$$ LANGUAGE plpgsql;


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

  IF raw_housenumber ~ '[^0-9;]' THEN
    RETURN display_housenumber_nonnumeric(raw_housenumber);
  END IF;

  -- Find the minimum and maximum numbers in the list
  SELECT MIN(value), MAX(value) INTO min_number, max_number
  FROM unnest(string_to_array(raw_housenumber, ';')::int[]) AS value;

  -- Return the consolidated range string
  RETURN min_number::text || '–' || max_number::text;
END;
$$ LANGUAGE plpgsql;
