CREATE OR REPLACE FUNCTION park_class(landuse TEXT, leisure TEXT, boundary TEXT) RETURNS TEXT AS $$
    SELECT CASE
        WHEN leisure = 'nature_reserve' OR boundary='national_park' THEN 'national_park'
        WHEN landuse IN ('recreation_ground', 'village_green') or leisure = 'park' THEN 'public_park'
         ELSE NULL
     END;
$$ LANGUAGE SQL IMMUTABLE;
