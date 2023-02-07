CREATE OR REPLACE FUNCTION park_class(boundary text, leisure text, landuse text, historic text)
    RETURNS text AS
$$
SELECT CASE 
    WHEN boundary = 'national_park' THEN 'national_park'
    WHEN leisure = 'nature_reserve' THEN 'nature_reserve'
    WHEN landuse = 'recreation_ground' THEN 'recreation_ground'
    WHEN historic <> '' THEN 'historic'
    ELSE 'nature_reserve' END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;
