-- etldoc: layer_park[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_park |<z4> z4 |<z5> z5 |<z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_park(bbox geometry, zoom_level int, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                class    text,
                name     text,
                name_en  text,
                name_de  text,
                tags     hstore,
                rank     int
            )
AS
$$
SELECT osm_id,
       geometry,
       class,
       NULLIF(name, '') AS name,
       NULLIF(name_en, '') AS name_en,
       NULLIF(name_de, '') AS name_de,
       tags,
       rank
FROM (
         SELECT osm_id,
                geometry,
                COALESCE(
                        LOWER(REPLACE(NULLIF(protection_title, ''), ' ', '_')),
                        NULLIF(boundary, ''),
                        NULLIF(leisure, '')
                    ) AS class,
                name,
                name_en,
                name_de,
                tags,
                NULL::int AS rank
         FROM (
                  -- etldoc: osm_park_polygon_dissolve_z4 -> layer_park:z4
                  SELECT NULL::int AS osm_id,
                         geometry,
                         NULL AS name,
                         NULL AS name_en,
                         NULL AS name_de,
                         NULL AS tags,
                         NULL AS leisure,
                         NULL AS boundary,
                         NULL AS protection_title
                  FROM osm_park_polygon_dissolve_z4
                  WHERE zoom_level = 4
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z5 -> layer_park:z5
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z5
                  WHERE zoom_level = 5
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z6 -> layer_park:z6
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z6
                  WHERE zoom_level = 6
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z7 -> layer_park:z7
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z7
                  WHERE zoom_level = 7
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z8 -> layer_park:z8
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z8
                  WHERE zoom_level = 8
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z9 -> layer_park:z9
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z9
                  WHERE zoom_level = 9
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z10 -> layer_park:z10
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z10
                  WHERE zoom_level = 10
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z11 -> layer_park:z11
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z11
                  WHERE zoom_level = 11
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z12 -> layer_park:z12
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z12
                  WHERE zoom_level = 12
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon_gen_z13 -> layer_park:z13
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon_gen_z13
                  WHERE zoom_level = 13
                    AND geometry && bbox
                  UNION ALL
                  -- etldoc: osm_park_polygon -> layer_park:z14
                  SELECT osm_id,
                         geometry,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title
                  FROM osm_park_polygon
                  WHERE zoom_level >= 14
                    AND geometry && bbox
              ) AS park_polygon

         UNION ALL
         SELECT osm_id,
                geometry_point AS geometry,
                COALESCE(
                        LOWER(REPLACE(NULLIF(protection_title, ''), ' ', '_')),
                        NULLIF(boundary, ''),
                        NULLIF(leisure, '')
                    ) AS class,
                name,
                name_en,
                name_de,
                tags,
                row_number() OVER (
                    PARTITION BY LabelGrid(geometry_point, 100 * pixel_width)
                    ORDER BY
                        (CASE WHEN boundary = 'national_park' THEN TRUE ELSE FALSE END) DESC,
                        (COALESCE(NULLIF(tags->'wikipedia', ''), NULLIF(tags->'wikidata', '')) IS NOT NULL) DESC,
                        area DESC
                    )::int AS "rank"
         FROM (
                  -- etldoc: osm_park_polygon_gen_z5 -> layer_park:z5
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z5
                  WHERE zoom_level = 5
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z6 -> layer_park:z6
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z6
                  WHERE zoom_level = 6
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z7 -> layer_park:z7
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z7
                  WHERE zoom_level = 7
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z8 -> layer_park:z8
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z8
                  WHERE zoom_level = 8
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z9 -> layer_park:z9
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z9
                  WHERE zoom_level = 9
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z10 -> layer_park:z10
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z10
                  WHERE zoom_level = 10
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z11 -> layer_park:z11
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z11
                  WHERE zoom_level = 11
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z12 -> layer_park:z12
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z12
                  WHERE zoom_level = 12
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon_gen_z13 -> layer_park:z13
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon_gen_z13
                  WHERE zoom_level = 13
                    AND geometry_point && bbox
                    AND area > 70000*2^(20-zoom_level)
                  UNION ALL

                  -- etldoc: osm_park_polygon -> layer_park:z14
                  SELECT osm_id,
                         geometry_point,
                         name,
                         name_en,
                         name_de,
                         tags,
                         leisure,
                         boundary,
                         protection_title,
                         area
                  FROM osm_park_polygon
                  WHERE zoom_level >= 14
                    AND geometry_point && bbox
              ) AS park_point
     ) AS park_all;
$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;
-- TODO: Check if the above can be made STRICT -- i.e. if pixel_width could be NULL
