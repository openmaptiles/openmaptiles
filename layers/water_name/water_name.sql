-- etldoc: layer_water_name[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_water_name | <z0_8> z0_8 | <z9_13> z9_13 | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_water_name(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                osm_id       bigint,
                geometry     geometry,
                name         text,
                name_en      text,
                name_de      text,
                tags         hstore,
                class        text,
                intermittent int
            )
AS
$$
SELECT
    -- etldoc: osm_water_lakeline ->  layer_water_name:z9_13
    -- etldoc: osm_water_lakeline ->  layer_water_name:z14_
    CASE
        WHEN osm_id < 0 THEN -osm_id * 10 + 4
        ELSE osm_id * 10 + 1
        END AS osm_id_hash,
    geometry,
    name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
    tags,
    'lake'::text AS class,
    is_intermittent::int AS intermittent
FROM osm_water_lakeline
WHERE geometry && bbox
  AND ((zoom_level BETWEEN 3 AND 13 AND LineLabel(zoom_level, NULLIF(name, ''), geometry))
    OR (zoom_level >= 14))
UNION ALL
SELECT
    -- etldoc: osm_water_point ->  layer_water_name:z9_13
    -- etldoc: osm_water_point ->  layer_water_name:z14_
    CASE
        WHEN osm_id < 0 THEN -osm_id * 10 + 4
        ELSE osm_id * 10 + 1
        END AS osm_id_hash,
    geometry,
    name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
    tags,
    class,
    is_intermittent::int AS intermittent
FROM osm_water_point
WHERE geometry && bbox
  AND (
        -- Show a label if a water feature covers at least 1/4 of a tile or z14+
        (tags->'place' IN ('sea', 'ocean') AND POWER(4,zoom_level) * earth_area > 0.25)
        OR (zoom_level BETWEEN 3 AND 13 AND POWER(4,zoom_level) * earth_area > 0.25)
        OR (zoom_level >= 14)
    )
UNION ALL
SELECT
    -- etldoc: osm_marine_point ->  layer_water_name:z0_8
    -- etldoc: osm_marine_point ->  layer_water_name:z9_13
    -- etldoc: osm_marine_point ->  layer_water_name:z14_
    osm_id * 10 AS osm_id_hash,
    geometry,
    name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
    tags,
    COALESCE(NULLIF("natural",''), "place") AS class,
    is_intermittent::int AS intermittent
FROM osm_marine_point
WHERE geometry && bbox
  AND CASE
      WHEN place = 'ocean' THEN TRUE
      WHEN zoom_level >= "rank" AND "rank" IS NOT NULL THEN TRUE
      WHEN "natural" = 'bay' THEN zoom_level >= 13
      ELSE zoom_level >= 8 END;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
