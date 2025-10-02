CREATE OR REPLACE FUNCTION park_class(boundary text, leisure text, landuse text, historic text, maritime boolean, tags hstore)
    RETURNS text AS
$$
SELECT CASE 
    WHEN maritime = TRUE THEN 'marine'
    WHEN boundary = 'national_park' THEN 'national_park'
    WHEN boundary = 'protected_area' THEN 
        COALESCE(
            NULLIF(tags->'protected_area', ''),
            NULLIF(tags->'protection_title', ''),
            'protected_area'
        )
    WHEN leisure = 'nature_reserve' THEN 'nature_reserve'
    WHEN landuse = 'recreation_ground' THEN 'recreation_ground'
    WHEN historic <> '' THEN 'historic'
    ELSE 'nature_reserve' END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;
