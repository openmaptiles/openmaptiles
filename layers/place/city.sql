
-- etldoc: layer_city[shape=record fillcolor=lightpink, style="rounded,filled",  
-- etldoc:     label="layer_city | <z2> z2 |<z3> z3 |<z4> z4 |<z5> z5|  <z6> z6 |<z7> z7 | <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14_" ] ;

CREATE OR REPLACE FUNCTION layer_city(bbox geometry, zoom_level int, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, class city_class, "rank" int) AS $$
    -- etldoc: osm_city_point -> layer_city:z2
    -- etldoc: osm_city_point -> layer_city:z3
    -- etldoc: osm_city_point -> layer_city:z4
    -- etldoc: osm_city_point -> layer_city:z5
    -- etldoc: osm_city_point -> layer_city:z6
    -- etldoc: osm_city_point -> layer_city:z7                
    SELECT osm_id, geometry, name, COALESCE(NULLIF(name_en, ''), name) AS name_en, place AS class, "rank"
    FROM osm_city_point
    WHERE geometry && bbox
      AND ((zoom_level = 2 AND "rank" = 1)
        OR (zoom_level BETWEEN 3 AND 7 AND "rank" <= zoom_level)
      )
    UNION ALL
    SELECT osm_id, geometry, name,
        COALESCE(NULLIF(name_en, ''), name) AS name_en,
        place AS class,
        COALESCE("rank", gridrank + 10)
    FROM (
      SELECT osm_id, geometry, name, name_en, place, "rank",
      row_number() OVER (
        PARTITION BY LabelGrid(geometry, 128 * pixel_width)
        ORDER BY "rank" ASC NULLS LAST,
        place ASC NULLS LAST,
        population DESC NULLS LAST,
        length(name) ASC
      )::int AS gridrank
    -- etldoc: osm_city_point -> layer_city:z8
    -- etldoc: osm_city_point -> layer_city:z9
    -- etldoc: osm_city_point -> layer_city:z10
    -- etldoc: osm_city_point -> layer_city:z11
    -- etldoc: osm_city_point -> layer_city:z12
    -- etldoc: osm_city_point -> layer_city:z13
    -- etldoc: osm_city_point -> layer_city:z14_                              
        FROM osm_city_point
        WHERE geometry && bbox
          AND ((zoom_level = 8 AND place <= 'town'::city_class)
            OR (zoom_level BETWEEN 9 AND 10 AND place <= 'village'::city_class)
            OR (zoom_level BETWEEN 11 AND 13 AND place <= 'suburb'::city_class)
            OR (zoom_level >= 14)
          )
    ) AS ranked_places
    WHERE (zoom_level = 8 AND (gridrank <= 4 OR "rank" IS NOT NULL))
       OR (zoom_level = 9 AND (gridrank <= 8 OR "rank" IS NOT NULL))
       OR (zoom_level = 10 AND (gridrank <= 12 OR "rank" IS NOT NULL))
       OR (zoom_level BETWEEN 11 AND 12 AND (gridrank <= 14 OR "rank" IS NOT NULL))
       OR (zoom_level >= 13)
    ORDER BY "rank" ASC;
$$ LANGUAGE SQL IMMUTABLE;
