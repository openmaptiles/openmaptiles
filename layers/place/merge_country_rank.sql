WITH important_country_point AS (
    SELECT osm.geometry, osm.osm_id, osm.name, COALESCE(NULLIF(osm.name_en, ''), ne.name) AS name_en, ne.labelrank
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
-- We merge the labelrank not scalerank because it is more fine grained
-- and allows styling more important countries bigger than others
SET "rank" = ne.labelrank
FROM important_country_point AS ne
WHERE osm.osm_id = ne.osm_id;

UPDATE osm_country_point AS osm
SET "rank" = 6
WHERE "rank" <= 0 OR "rank" > 6 OR "rank" IS NULL;

ALTER TABLE osm_country_point DROP CONSTRAINT IF EXISTS osm_country_point_rank_constraint;
ALTER TABLE osm_country_point ADD CONSTRAINT osm_country_point_rank_constraint CHECK("rank" BETWEEN 1 AND 6);

CREATE INDEX IF NOT EXISTS osm_country_point_rank_idx ON osm_country_point("rank");
