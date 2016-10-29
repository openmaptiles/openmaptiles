ALTER TABLE osm_country_point DROP CONSTRAINT IF EXISTS osm_country_point_rank_constraint;

WITH important_country_point AS (
    SELECT osm.geometry, osm.osm_id, osm.name, COALESCE(NULLIF(osm.name_en, ''), ne.name) AS name_en, ne.scalerank, ne.labelrank
    FROM ne_10m_admin_0_countries AS ne, osm_country_point AS osm
    WHERE
    -- We only match whether the point is within the Natural Earth polygon
    -- because name matching is to difficult since OSM does not contain good
    -- enough coverage of ISO codes
    ST_Within(osm.geometry, ne.geom)
    -- We leave out tiny countries
    AND ne.scalerank <= 1
)
UPDATE osm_country_point AS osm
-- Normalize both scalerank and labelrank into a ranking system from 1 to 6
-- Scaleranks for NE countries range from 0 to 6 and labelranks range from 2 to 10.
-- This means a max combined rank of 16 divided by 3 to get us uniform ranking from 1 to 6
SET "rank" = CEILING((scalerank + labelrank)/3.0)
FROM important_country_point AS ne
WHERE osm.osm_id = ne.osm_id;

UPDATE osm_country_point AS osm
SET "rank" = 6
WHERE "rank" < 0 OR "rank" > 6 OR "rank" IS NULL;

ALTER TABLE osm_country_point ADD CONSTRAINT osm_country_point_rank_constraint CHECK("rank" BETWEEN 1 AND 6);
CREATE INDEX IF NOT EXISTS osm_country_point_rank_idx ON osm_country_point("rank");