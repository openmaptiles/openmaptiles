CREATE OR REPLACE FUNCTION normalize_capital_level(capital text)
    RETURNS int AS
$$
SELECT CASE
           WHEN capital = 'yes' THEN 2
           WHEN capital IN ('2', '4', '6') THEN capital::int
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;
