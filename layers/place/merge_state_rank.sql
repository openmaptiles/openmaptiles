ALTER TABLE osm_state_point DROP CONSTRAINT IF EXISTS osm_state_point_rank_constraint;

-- etldoc: ne_10m_admin_1_states_provinces_shp   -> osm_state_point
-- etldoc: osm_state_point                       -> osm_state_point

WITH important_state_point AS (
    SELECT osm.geometry, osm.osm_id, osm.name, COALESCE(NULLIF(osm.name_en, ''), ne.name) AS name_en, ne.scalerank, ne.labelrank, ne.datarank
    FROM ne_10m_admin_1_states_provinces_shp AS ne, osm_state_point AS osm
    WHERE
    -- We only match whether the point is within the Natural Earth polygon
    -- because name matching is difficult
    ST_Within(osm.geometry, ne.geometry)
    -- We leave out leess important states
    AND ne.scalerank <= 3 AND ne.labelrank <= 2
)
UPDATE osm_state_point AS osm
-- Normalize both scalerank and labelrank into a ranking system from 1 to 6.
SET "rank" = LEAST(6, CEILING((scalerank + labelrank + datarank)/3.0))
FROM important_state_point AS ne
WHERE osm.osm_id = ne.osm_id;

-- TODO: This shouldn't be necessary? The rank function makes something wrong...
UPDATE osm_state_point AS osm
SET "rank" = 1
WHERE "rank" = 0;

DELETE FROM osm_state_point WHERE "rank" IS NULL;

ALTER TABLE osm_state_point ADD CONSTRAINT osm_state_point_rank_constraint CHECK("rank" BETWEEN 1 AND 6);
CREATE INDEX IF NOT EXISTS osm_state_point_rank_idx ON osm_state_point("rank");
