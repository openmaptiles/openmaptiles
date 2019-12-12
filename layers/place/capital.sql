CREATE OR REPLACE FUNCTION normalize_capital_level(capital TEXT)
RETURNS INT AS $$
    SELECT CASE
        WHEN capital IN ('yes', '2') THEN 2
        WHEN capital = '4' THEN 4
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;
