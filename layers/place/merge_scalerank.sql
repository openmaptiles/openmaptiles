WITH important_country_point AS (
    SELECT osm.geometry, osm.osm_id, osm.name, osm.name_en, ne.scalerank
    FROM ne_10m_admin_0_countries AS ne, osm_country_point AS osm
    WHERE
    (
        ne.name ILIKE osm.name OR
        ne.name ILIKE osm.name_en OR
        ne.adm0_a3 ILIKE osm.country_code_fips
    )
    AND ST_Within(osm.geometry, ne.geom)
)
UPDATE osm_country_point AS osm
SET scalerank = ne.scalerank
FROM important_country_point AS ne
WHERE osm.osm_id = ne.osm_id;

DELETE FROM osm_state_point
WHERE is_in_country IN ('United Kingdom', 'USA', 'Россия', 'Brasil', 'China', 'India')
   OR is_in_country_code IN ('AU', 'CN', 'IN', 'BR', 'US');

CREATE INDEX IF NOT EXISTS osm_country_point_scalerank_idx ON osm_country_point(scalerank);

WITH important_city_point AS (
    SELECT osm.geometry, osm.osm_id, osm.name, osm.name_en, ne.scalerank
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
SET scalerank = ne.scalerank
FROM important_city_point AS ne
WHERE osm.osm_id = ne.osm_id;

CREATE INDEX IF NOT EXISTS osm_city_point_scalerank_idx ON osm_city_point(scalerank);
