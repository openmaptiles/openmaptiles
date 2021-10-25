-- etldoc: layer_park[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_park |<z4> z4 |<z5> z5 |<z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_park(bbox geometry, zoom_level int, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                attr     jsonb
            )
AS
$$

-- etldoc: osm_park_polygon_geometry -> layer_park:z4
SELECT NULL::int AS osm_id,
       geometry,
       '{}'::jsonb AS attr
FROM osm_park_polygon_dissolve_z4
WHERE zoom_level = 4
AND geometry && bbox

UNION ALL

SELECT (tile).*
FROM (
         -- etldoc: osm_park_polygon_gen_z5 -> layer_park:z5
         SELECT park_polygon_tile(ROW(t.*)::park_polygon_gen_t) AS tile
         FROM osm_park_polygon_gen_z5 t
         WHERE zoom_level = 5
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_park_polygon_gen_z6 -> layer_park:z6
         SELECT park_polygon_tile(ROW(t.*)::park_polygon_gen_t) AS tile
         FROM osm_park_polygon_gen_z6 t
         WHERE zoom_level = 6
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_park_polygon_gen_z7 -> layer_park:z7
         SELECT park_polygon_tile(ROW(t.*)::park_polygon_gen_t) AS tile
         FROM osm_park_polygon_gen_z7 t
         WHERE zoom_level = 7
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_park_polygon_gen_z8 -> layer_park:z8
         SELECT park_polygon_tile(ROW(t.*)::park_polygon_gen_t) AS tile
         FROM osm_park_polygon_gen_z8 t
         WHERE zoom_level = 8
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_park_polygon_gen_z9 -> layer_park:z9
         SELECT park_polygon_tile(ROW(t.*)::park_polygon_gen_t) AS tile
         FROM osm_park_polygon_gen_z9 t
         WHERE zoom_level = 9
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_park_polygon_gen_z10 -> layer_park:z10
         SELECT park_polygon_tile(ROW(t.*)::park_polygon_gen_t) AS tile
         FROM osm_park_polygon_gen_z10 t
         WHERE zoom_level = 10
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_park_polygon_gen_z11 -> layer_park:z11
         SELECT park_polygon_tile(ROW(t.*)::park_polygon_gen_t) AS tile
         FROM osm_park_polygon_gen_z11 t
         WHERE zoom_level = 11
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_park_polygon_gen_z12 -> layer_park:z12
         SELECT park_polygon_tile(ROW(t.*)::park_polygon_gen_t) AS tile
         FROM osm_park_polygon_gen_z12 t
         WHERE zoom_level = 12
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_park_polygon_gen_z13 -> layer_park:z13
         SELECT park_polygon_tile(ROW(t.*)::park_polygon_gen_t) AS tile
         FROM osm_park_polygon_gen_z13 t
         WHERE zoom_level = 13
         AND geometry && bbox

         UNION ALL

         -- etldoc: osm_park_polygon -> layer_park:z14
         SELECT park_polygon_tile(ROW(t.*)::park_polygon_t) AS tile
         FROM osm_park_polygon t
         WHERE zoom_level >= 14
         AND geometry && bbox

     ) AS park_polygons_all

UNION ALL

SELECT (tile).osm_id,
       (tile).geom,
       (tile).attr ||
           jsonb_build_object('rank',
               row_number() OVER (
                   PARTITION BY LabelGrid((tile).geom, 100 * pixel_width)
                   ORDER BY
                       (CASE WHEN tags->'boundary' = 'national_park' THEN TRUE ELSE FALSE END) DESC,
                       (COALESCE(NULLIF(tags->'wikipedia', ''), NULLIF(tags->'wikidata', '')) IS NOT NULL) DESC,
                   area DESC
               )::int
           )
FROM (

       -- etldoc: osm_park_polygon_gen_z5 -> layer_park:z5
       SELECT park_point_tile(ROW(t.*)::park_polygon_gen_t) AS tile,
              tags,
              area
       FROM osm_park_polygon_gen_z5 t
       WHERE zoom_level = 5
       AND geometry && bbox

       UNION ALL

       -- etldoc: osm_park_polygon_gen_z6 -> layer_park:z6
       SELECT park_point_tile(ROW(t.*)::park_polygon_gen_t) AS tile,
              tags,
              area
       FROM osm_park_polygon_gen_z6 t
       WHERE zoom_level = 6
       AND geometry && bbox

       UNION ALL

       -- etldoc: osm_park_polygon_gen_z7 -> layer_park:z7
       SELECT park_point_tile(ROW(t.*)::park_polygon_gen_t) AS tile,
              tags,
              area
       FROM osm_park_polygon_gen_z7 t
       WHERE zoom_level = 7
       AND geometry && bbox

       UNION ALL

       -- etldoc: osm_park_polygon_gen_z8 -> layer_park:z8
       SELECT park_point_tile(ROW(t.*)::park_polygon_gen_t) AS tile,
              tags,
              area
       FROM osm_park_polygon_gen_z8 t
       WHERE zoom_level = 8
       AND geometry && bbox

       UNION ALL

       -- etldoc: osm_park_polygon_gen_z9 -> layer_park:z9
       SELECT park_point_tile(ROW(t.*)::park_polygon_gen_t) AS tile,
              tags,
              area
       FROM osm_park_polygon_gen_z9 t
       WHERE zoom_level = 9
       AND geometry && bbox

       UNION ALL

       -- etldoc: osm_park_polygon_gen_z10 -> layer_park:z10
       SELECT park_point_tile(ROW(t.*)::park_polygon_gen_t) AS tile,
              tags,
              area
       FROM osm_park_polygon_gen_z10 t
       WHERE zoom_level = 10
       AND geometry && bbox

       UNION ALL

       -- etldoc: osm_park_polygon_gen_z11 -> layer_park:z11
       SELECT park_point_tile(ROW(t.*)::park_polygon_gen_t) AS tile,
              tags,
              area
       FROM osm_park_polygon_gen_z11 t
       WHERE zoom_level = 11
       AND geometry && bbox

       UNION ALL

       -- etldoc: osm_park_polygon_gen_z12 -> layer_park:z12
       SELECT park_point_tile(ROW(t.*)::park_polygon_gen_t) AS tile,
              tags,
              area
       FROM osm_park_polygon_gen_z12 t
       WHERE zoom_level = 12
       AND geometry && bbox

       UNION ALL

       -- etldoc: osm_park_polygon_gen_z13 -> layer_park:z13
       SELECT park_point_tile(ROW(t.*)::park_polygon_gen_t) AS tile,
              tags,
              area
       FROM osm_park_polygon_gen_z13 t
       WHERE zoom_level = 13
       AND geometry && bbox

       UNION ALL

       -- etldoc: osm_park_polygon -> layer_park:z14
       SELECT park_point_tile(ROW(t.*)::park_polygon_t) AS tile,
              tags,
              area
       FROM osm_park_polygon t
       WHERE zoom_level >= 14
       AND geometry && bbox

     ) AS park_points_all

$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;
