-- etldoc: layer_park_label[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_park |<z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_park_label(bbox geometry, zoom_level int, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, name_de text, tags hstore, class text, rank int) AS $$
    SELECT osm_id, geometry_point, name, name_en, name_de, tags,
        COALESCE(NULLIF(boundary, ''), NULLIF(leisure, '')) AS class,
        row_number() OVER (
           PARTITION BY LabelGrid(geometry_point, 100 * pixel_width)
           ORDER BY
               (CASE WHEN boundary = 'national_park' THEN true ELSE false END) DESC,
               (COALESCE(NULLIF(tags->'wikipedia', ''), NULLIF(tags->'wikidata', '')) IS NOT NULL) DESC,
               area DESC
        )::int AS "rank"
        FROM (
        -- etldoc: osm_park_polygon_gen8 -> layer_park_label:z6
        SELECT osm_id, geometry_point, name, name_en, name_de, tags, leisure, boundary, area
        FROM osm_park_polygon_gen8
        WHERE zoom_level = 6
        UNION ALL

        -- etldoc: osm_park_polygon_gen7 -> layer_park_label:z7
        SELECT osm_id, geometry_point, name, name_en, name_de, tags, leisure, boundary, area
        FROM osm_park_polygon_gen7
        WHERE zoom_level = 7
        UNION ALL

        -- etldoc: osm_park_polygon_gen6 -> layer_park_label:z8
        SELECT osm_id, geometry_point, name, name_en, name_de, tags, leisure, boundary, area
        FROM osm_park_polygon_gen6
        WHERE zoom_level = 8
        UNION ALL

        -- etldoc: osm_park_polygon_gen5 -> layer_park_label:z9
        SELECT osm_id, geometry_point, name, name_en, name_de, tags, leisure, boundary, area
        FROM osm_park_polygon_gen5
        WHERE zoom_level = 9
        UNION ALL

        -- etldoc: osm_park_polygon_gen4 -> layer_park_label:z10
        SELECT osm_id, geometry_point, name, name_en, name_de, tags, leisure, boundary, area
        FROM osm_park_polygon_gen4
        WHERE zoom_level = 10
        UNION ALL

        -- etldoc: osm_park_polygon_gen3 -> layer_park_label:z11
        SELECT osm_id, geometry_point, name, name_en, name_de, tags, leisure, boundary, area
        FROM osm_park_polygon_gen3
        WHERE zoom_level = 11
        UNION ALL

        -- etldoc: osm_park_polygon_gen2 -> layer_park_label:z12
        SELECT osm_id, geometry_point, name, name_en, name_de, tags, leisure, boundary, area
        FROM osm_park_polygon_gen2
        WHERE zoom_level = 12
        UNION ALL

        -- etldoc: osm_park_polygon_gen1 -> layer_park_label:z13
        SELECT osm_id, geometry_point, name, name_en, name_de, tags, leisure, boundary, area
        FROM osm_park_polygon_gen1
        WHERE zoom_level = 13
        UNION ALL

        -- etldoc: osm_park_polygon -> layer_park_label:z14
        SELECT osm_id, geometry_point, name, name_en, name_de, tags, leisure, boundary, area
        FROM osm_park_polygon
        WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry_point && bbox;
$$ LANGUAGE SQL IMMUTABLE;
