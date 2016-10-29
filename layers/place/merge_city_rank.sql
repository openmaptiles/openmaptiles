WITH important_city_point AS (
    SELECT osm.geometry, osm.osm_id, osm.name, osm.name_en, ne.scalerank, ne.labelrank
    FROM ne_10m_populated_places AS ne, osm_city_point AS osm
    WHERE
    (
        ne.name ILIKE osm.name OR
        ne.name ILIKE osm.name_en OR
        ne.namealt ILIKE osm.name OR
        ne.namealt ILIKE osm.name_en OR
        ne.meganame ILIKE osm.name OR
        ne.meganame ILIKE osm.name_en OR
        ne.gn_ascii ILIKE osm.name OR
        ne.gn_ascii ILIKE osm.name_en OR
        ne.nameascii ILIKE osm.name OR
        ne.nameascii ILIKE osm.name_en
    )
    AND (osm.place = 'city'::city_class OR osm.place= 'town'::city_class OR osm.place = 'village'::city_class)
    AND ST_DWithin(ne.geom, osm.geometry, 50000)
)
UPDATE osm_city_point AS osm
-- Normalize both scalerank and labelrank into a ranking system from 1 to 10.
-- Scaleranks for NE populated place range from 0 to 8 and labelranks range from 0 to 10.
-- To give features with both ranks close to 0 a lower rank we increase the range from 1 to 9 and 1 to 11.
-- This means a max combined rank of 20 divided by 2 to get us uniform ranking from 1 to 10
SET "rank" = CEILING((ne.scalerank + 1 + ne.labelrank + 1)/2.0)
FROM important_city_point AS ne
WHERE osm.osm_id = ne.osm_id;

CREATE INDEX IF NOT EXISTS osm_city_point_rank_idx ON osm_city_point("rank");
