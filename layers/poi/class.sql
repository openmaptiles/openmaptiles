CREATE OR REPLACE FUNCTION poi_class_rank(class TEXT)
RETURNS INT AS $$
    SELECT CASE class
        WHEN 'hospital' THEN 20
        WHEN 'railway' THEN 40
        WHEN 'bus' THEN 50
        WHEN 'attraction' THEN 70
        WHEN 'harbor' THEN 75
        WHEN 'college' THEN 80
        WHEN 'school' THEN 85
        WHEN 'stadium' THEN 90
        WHEN 'zoo' THEN 95
        WHEN 'town_hall' THEN 100
        WHEN 'campsite' THEN 110
        WHEN 'cemetery' THEN 115
        WHEN 'park' THEN 120
        WHEN 'library' THEN 130
        WHEN 'police' THEN 135
        WHEN 'post' THEN 140
        WHEN 'golf' THEN 150
        WHEN 'shop' THEN 400
        WHEN 'grocery' THEN 500
        WHEN 'fast_food' THEN 600
        WHEN 'clothing_store' THEN 700
        WHEN 'bar' THEN 800
        ELSE 1000
    END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION poi_class(subclass TEXT, mapping_key TEXT)
RETURNS TEXT AS $$
    SELECT CASE
        %%FIELD_MAPPING: class %%
        ELSE subclass
    END;
$$ LANGUAGE SQL IMMUTABLE;
