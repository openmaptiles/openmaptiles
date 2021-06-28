CREATE OR REPLACE FUNCTION highway_to_val(hwy_class varchar)
RETURNS int
IMMUTABLE
LANGUAGE plpgsql
AS $$
BEGIN
  CASE hwy_class
    WHEN 'motorway'     THEN RETURN 6;
    WHEN 'trunk'        THEN RETURN 5;
    WHEN 'primary'      THEN RETURN 4;
    WHEN 'secondary'    THEN RETURN 3;
    WHEN 'tertiary'     THEN RETURN 2;
    WHEN 'unclassified' THEN RETURN 1;
    else RETURN 0;
  END CASE;
END;
$$;

CREATE OR REPLACE FUNCTION val_to_highway(hwy_val int)
RETURNS varchar
IMMUTABLE
LANGUAGE plpgsql
AS $$
BEGIN
  CASE hwy_val
    WHEN 6 THEN RETURN 'motorway';
    WHEN 5 THEN RETURN 'trunk';
    WHEN 4 THEN RETURN 'primary';
    WHEN 3 THEN RETURN 'secondary';
    WHEN 2 THEN RETURN 'tertiary';
    WHEN 1 THEN RETURN 'unclassified';
    else RETURN null;
  END CASE;
END;
$$;

CREATE OR REPLACE FUNCTION highest_hwy_sfunc(agg_state varchar, hwy_class varchar)
RETURNS varchar
IMMUTABLE
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN val_to_highway(
    GREATEST(
      highway_to_val(agg_state),
      highway_to_val(hwy_class)
    )
  );
END;
$$;

DROP AGGREGATE IF EXISTS highest_highway (varchar);
CREATE AGGREGATE highest_highway (varchar)
(
    sfunc = highest_hwy_sfunc,
    stype = varchar
);
