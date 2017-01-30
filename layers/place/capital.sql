CREATE OR REPLACE FUNCTION place.normalize_capital_level(capital TEXT)
RETURNS INT AS $$
    SELECT CASE
        WHEN capital IN ('yes', '2') THEN 2
        WHEN capital = '4' THEN 4
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;
