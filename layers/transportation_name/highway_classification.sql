CREATE OR REPLACE FUNCTION highway_to_val(hwy_class varchar)
RETURNS int
IMMUTABLE
LANGUAGE sql
AS $$
  SELECT CASE hwy_class
    WHEN 'motorway'     THEN 6
    WHEN 'trunk'        THEN 5
    WHEN 'primary'      THEN 4
    WHEN 'secondary'    THEN 3
    WHEN 'tertiary'     THEN 2
    WHEN 'unclassified' THEN 1
    ELSE 0
  END;
$$;

CREATE OR REPLACE FUNCTION val_to_highway(hwy_val int)
RETURNS varchar
IMMUTABLE
LANGUAGE sql
AS $$
  SELECT CASE hwy_val
    WHEN 6 THEN 'motorway'
    WHEN 5 THEN 'trunk'
    WHEN 4 THEN 'primary'
    WHEN 3 THEN 'secondary'
    WHEN 2 THEN 'tertiary'
    WHEN 1 THEN 'unclassified'
    ELSE null
  END;
$$;

CREATE OR REPLACE FUNCTION highest_hwy_sfunc(agg_state varchar, hwy_class varchar)
RETURNS varchar
IMMUTABLE
LANGUAGE sql
AS $$
  SELECT val_to_highway(
    GREATEST(
      highway_to_val(agg_state),
      highway_to_val(hwy_class)
    )
  );
$$;

DROP AGGREGATE IF EXISTS highest_highway (varchar);
CREATE AGGREGATE highest_highway (varchar)
(
    sfunc = highest_hwy_sfunc,
    stype = varchar
);
