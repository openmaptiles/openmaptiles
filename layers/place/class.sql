CREATE OR REPLACE FUNCTION place_class(place TEXT)
RETURNS TEXT AS $$
    SELECT CASE
        WHEN place IN ('city', 'town', 'village', 'hamlet', 'isolated_dwelling') THEN 'settlement'
        WHEN place IN ('suburb', 'neighbourhood') THEN 'subregion'
        WHEN place IN ('locality', 'farm') THEN 'other'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION normalize_capital_level(capital TEXT)
RETURNS INT AS $$
    SELECT CASE
        WHEN capital IN ('yes', '2') THEN 2
        WHEN capital = '4' THEN 4
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;
