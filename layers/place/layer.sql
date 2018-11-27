
-- etldoc: layer_place[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_place | <z0_3> z0-3|<z4_7> z4-7|<z8_11> z8-11| <z12_14> z12-z14+" ] ;

CREATE OR REPLACE FUNCTION layer_place(bbox geometry, zoom_level int, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text,
    name_de text, tags hstore, class text, "rank" int, capital INT, iso_a2
        TEXT) AS $$
    SELECT * FROM (

    -- etldoc: osm_continent_point -> layer_place:z0_3
    SELECT
        osm_id*10, geometry, name,
        COALESCE(NULLIF(name_en, ''), name) AS name_en,
        COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
        tags,
        'continent' AS class, 1 AS "rank", NULL::int AS capital,
        NULL::text AS iso_a2
    FROM osm_continent_point
    WHERE geometry && bbox AND zoom_level < 4
    UNION ALL

    -- etldoc: osm_country_point -> layer_place:z0_3
    -- etldoc: osm_country_point -> layer_place:z4_7
    -- etldoc: osm_country_point -> layer_place:z8_11
    -- etldoc: osm_country_point -> layer_place:z12_14
    SELECT
        osm_id*10, geometry, name,
        COALESCE(NULLIF(name_en, ''), name) AS name_en,
        COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
        tags,
        'country' AS class, "rank", NULL::int AS capital,
        iso3166_1_alpha_2 AS iso_a2
    FROM osm_country_point
    WHERE geometry && bbox AND "rank" <= zoom_level + 1 AND name <> ''
    UNION ALL

    -- etldoc: osm_state_point  -> layer_place:z0_3
    -- etldoc: osm_state_point  -> layer_place:z4_7
    -- etldoc: osm_state_point  -> layer_place:z8_11
    -- etldoc: osm_state_point  -> layer_place:z12_14
    SELECT
        osm_id*10, geometry, name,
        COALESCE(NULLIF(name_en, ''), name) AS name_en,
        COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
        tags,
        'state' AS class, "rank", NULL::int AS capital,
        NULL::text AS iso_a2
    FROM osm_state_point
    WHERE geometry && bbox AND
          name <> '' AND
          ("rank" + 2 <= zoom_level) AND (
              zoom_level >= 5 OR
              is_in_country IN ('United Kingdom', 'USA', 'Россия', 'Brasil', 'China', 'India') OR
              is_in_country_code IN ('AU', 'CN', 'IN', 'BR', 'US'))
    UNION ALL

    -- etldoc: osm_island_point    -> layer_place:z12_14
    SELECT
        osm_id*10, geometry, name,
        COALESCE(NULLIF(name_en, ''), name) AS name_en,
        COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
        tags,
        'island' AS class, 7 AS "rank", NULL::int AS capital,
        NULL::text AS iso_a2
    FROM osm_island_point
    WHERE zoom_level >= 12
        AND geometry && bbox
    UNION ALL

    -- etldoc: osm_island_polygon  -> layer_place:z8_11
    -- etldoc: osm_island_polygon  -> layer_place:z12_14
    SELECT
        osm_id*10, geometry, name,
        COALESCE(NULLIF(name_en, ''), name) AS name_en,
        COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
        tags,
        'island' AS class, island_rank(area) AS "rank", NULL::int AS capital,
        NULL::text AS iso_a2
    FROM osm_island_polygon
    WHERE geometry && bbox AND
        ((zoom_level = 8 AND island_rank(area) <= 3)
        OR (zoom_level = 9 AND island_rank(area) <= 4)
        OR (zoom_level >= 10))
    UNION ALL

    -- etldoc: layer_city          -> layer_place:z0_3
    -- etldoc: layer_city          -> layer_place:z4_7
    -- etldoc: layer_city          -> layer_place:z8_11
    -- etldoc: layer_city          -> layer_place:z12_14
    SELECT
        osm_id*10, geometry, name, name_en, name_de,
        tags,
        place::text AS class, "rank", capital,
        NULL::text AS iso_a2
    FROM layer_city(bbox, zoom_level, pixel_width)
    ORDER BY "rank" ASC
    ) AS place_all
$$ LANGUAGE SQL IMMUTABLE;
