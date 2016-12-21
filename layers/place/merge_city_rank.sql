
-- etldoc: ne_10m_populated_places -> osm_city_point
-- etldoc: osm_city_point          -> osm_city_point

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
    AND osm.place IN ('city', 'town', 'village')
    AND ST_DWithin(ne.geometry, osm.geometry, 50000)
)
UPDATE osm_city_point AS osm
-- Move scalerank to range 1 to 10 and merge scalerank 5 with 6 since not enough cities
-- are in the scalerank 5 bucket
SET "rank" = CASE WHEN scalerank <= 5 THEN scalerank + 1 ELSE scalerank END
FROM important_city_point AS ne
WHERE osm.osm_id = ne.osm_id;

CREATE INDEX IF NOT EXISTS osm_city_point_rank_idx ON osm_city_point("rank");
