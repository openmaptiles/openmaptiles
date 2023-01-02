-- Unify class names that represent the same type of feature
CREATE OR REPLACE FUNCTION landuse_unify(class text) RETURNS text LANGUAGE plpgsql
AS
$$
BEGIN
  RETURN CASE
    WHEN class='grave_yard' THEN 'cemetery'
    ELSE class END;
END;
$$;
