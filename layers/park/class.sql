

CREATE OR REPLACE FUNCTION protect_class_map(protect_class text)
    RETURNS text AS
$$
SELECT CASE 
    WHEN protect_class = '1a' THEN 'conservation'
    WHEN protect_class = '1b' THEN 'wilderness_preserve'
    WHEN protect_class = '2' THEN 'national_park'
    WHEN protect_class = '3' THEN 'conservation'
    WHEN protect_class = '4' THEN 'wildlife_refuge'
    WHEN protect_class = '5' THEN 'conservation'
    WHEN protect_class = '6' THEN 'sustainable'
    ELSE NULL
END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

CREATE OR REPLACE FUNCTION park_class(boundary text, leisure text, landuse text, historic text, maritime boolean, tags hstore)
    RETURNS text AS
$$
SELECT CASE 
    WHEN maritime = TRUE THEN 'marine'
    WHEN boundary = 'national_park' THEN 'national_park'
    WHEN boundary = 'protected_area' THEN 
        COALESCE(
            NULLIF(tags->'protected_area', ''),
            protect_class_map(tags->'protect_class'),
            NULLIF(tags->'protection_title', ''),
            'protected_area'
        )
    WHEN leisure = 'nature_reserve' THEN 'nature_reserve'
    WHEN landuse = 'recreation_ground' THEN 'recreation_ground'
    WHEN historic <> '' THEN 'historic'
    ELSE 'nature_reserve' END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;
