
-- etldoc: layer_place[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_place | <z0_3> z0-3|<z4_7> z4-7|<z8_11> z8-11| <z12_14> z12-z14+" ] ;

CREATE OR REPLACE FUNCTION place.layer_place(bbox geometry, zoom_level int, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, class text, "rank" int, capital INT) AS $$

    -- etldoc: osm_continent_point -> layer_place:z0_3
    SELECT
        osm_id, geometry, name, name_en,
        'continent' AS class, 1 AS "rank", NULL::int AS capital
    FROM osm_continent_point
    WHERE geometry && bbox AND zoom_level < 4
    UNION ALL

    -- etldoc: osm_country_point -> layer_place:z0_3
    -- etldoc: osm_country_point -> layer_place:z4_7
    -- etldoc: osm_country_point -> layer_place:z8_11
    -- etldoc: osm_country_point -> layer_place:z12_14
    SELECT
        osm_id, geometry, name, COALESCE(NULLIF(name_en, ''), name) AS name_en,
        'country' AS class, "rank", NULL::int AS capital
    FROM osm_country_point
    WHERE geometry && bbox AND "rank" <= zoom_level + 1 AND name <> ''
    UNION ALL

    -- etldoc: osm_state_point  -> layer_place:z0_3
    -- etldoc: osm_state_point  -> layer_place:z4_7
    -- etldoc: osm_state_point  -> layer_place:z8_11
    -- etldoc: osm_state_point  -> layer_place:z12_14
    SELECT
        osm_id, geometry, name, COALESCE(NULLIF(name_en, ''), name) AS name_en,
        'state' AS class, "rank", NULL::int AS capital
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
        osm_id, geometry, name, COALESCE(NULLIF(name_en, ''), name) AS name_en,
        'island' AS class, 7 AS "rank", NULL::int AS capital
    FROM osm_island_point
    WHERE zoom_level >= 12
        AND geometry && bbox
    UNION ALL

    -- etldoc: osm_island_polygon  -> layer_place:z8_11
    -- etldoc: osm_island_polygon  -> layer_place:z12_14
    SELECT
        osm_id, geometry, name, COALESCE(NULLIF(name_en, ''), name) AS name_en,
        'island' AS class, place.island_rank(area) AS "rank", NULL::int AS capital
    FROM osm_island_polygon
    WHERE geometry && bbox AND
        ((zoom_level = 8 AND place.island_rank(area) <= 3)
        OR (zoom_level = 9 AND place.island_rank(area) <= 4)
        OR (zoom_level >= 10))
    UNION ALL

    -- etldoc: layer_city          -> layer_place:z0_3
    -- etldoc: layer_city          -> layer_place:z4_7
    -- etldoc: layer_city          -> layer_place:z8_11
    -- etldoc: layer_city          -> layer_place:z12_14
    SELECT
        osm_id, geometry, name, name_en,
        place::text AS class, "rank", capital
    FROM place.layer_city(bbox, zoom_level, pixel_width)
    ORDER BY "rank" ASC
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION place.delete() RETURNS VOID AS $$
BEGIN
  DROP TRIGGER IF EXISTS trigger_flag ON osm_city_point;
  DROP TRIGGER IF EXISTS trigger_refresh ON place_city.updates;
  DROP SCHEMA IF EXISTS place_city CASCADE;
  DROP TRIGGER IF EXISTS trigger_flag ON osm_state_point;
  DROP TRIGGER IF EXISTS trigger_refresh ON place_state.updates;
  DROP SCHEMA IF EXISTS place_state CASCADE;
  DROP TRIGGER IF EXISTS trigger_flag ON osm_country_point;
  DROP TRIGGER IF EXISTS trigger_refresh ON place_country.updates;
  DROP SCHEMA IF EXISTS place_country CASCADE;
  DROP SCHEMA IF EXISTS place CASCADE;
  DROP TABLE IF EXISTS osm_continent_point CASCADE;
  DROP TABLE IF EXISTS osm_country_point CASCADE;
  DROP TABLE IF EXISTS osm_island_polygon CASCADE;
  DROP TABLE IF EXISTS osm_island_point CASCADE;
  DROP TABLE IF EXISTS osm_state_point CASCADE;
  DROP TABLE IF EXISTS osm_city_point CASCADE;
END;
$$ LANGUAGE plpgsql;
