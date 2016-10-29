ALTER TABLE osm_country_point DROP CONSTRAINT IF EXISTS osm_country_point_rank_constraint;

WITH important_country_point AS (
    SELECT osm.geometry, osm.osm_id, osm.name, COALESCE(NULLIF(osm.name_en, ''), ne.name) AS name_en, ne.scalerank, ne.labelrank
    FROM ne_10m_admin_0_countries AS ne, osm_country_point AS osm
    WHERE
    -- We only match whether the point is within the Natural Earth polygon
    -- because name matching is to difficult since OSM does not contain good
    -- enough coverage of ISO codesy
    ST_Within(osm.geometry, ne.geom)
    -- We leave out tiny countries
    AND ne.scalerank <= 1
)
UPDATE osm_country_point AS osm
-- Normalize both scalerank and labelrank into a ranking system from 1 to 6
-- where the ranks are still distributed uniform enough across all countries
SET "rank" = LEAST(6, CEILING((scalerank + labelrank)/2.0))
FROM important_country_point AS ne
WHERE osm.osm_id = ne.osm_id;

UPDATE osm_country_point AS osm
SET "rank" = 6
WHERE "rank" IS NULL;

ALTER TABLE osm_country_point ADD CONSTRAINT osm_country_point_rank_constraint CHECK("rank" BETWEEN 1 AND 6);
CREATE INDEX IF NOT EXISTS osm_country_point_rank_idx ON osm_country_point("rank");