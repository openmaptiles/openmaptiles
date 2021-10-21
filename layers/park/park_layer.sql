-- etldoc: layer_park[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_park |<z4> z4 |<z5> z5 |<z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_park(bbox geometry, zoom_level int, pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                attr     jsonb,
                rank     int
            )
AS
$$
SELECT ABS(osm_id),
       geometry,
       attr,
       rank
FROM (
         -- etldoc: osm_park_polygon_geometry -> layer_park:z5_
         SELECT osm_id,
                CASE
                  WHEN zoom_level = 5 THEN geom_z5
                  WHEN zoom_level = 6 THEN geom_z6
                  WHEN zoom_level = 7 THEN geom_z7
                  WHEN zoom_level = 8 THEN geom_z8
                  WHEN zoom_level = 9 THEN geom_z9
                  WHEN zoom_level = 10 THEN geom_z10
                  WHEN zoom_level = 11 THEN geom_z11
                  WHEN zoom_level = 12 THEN geom_z12
                  WHEN zoom_level = 13 THEN geom_z13
                  WHEN zoom_level >= 14 THEN geometry
               END AS geometry,
               attr,
               NULL::int AS rank
         FROM osm_park_polygon_geometry
         WHERE
           CASE
             WHEN zoom_level = 5 THEN geom_z5 && bbox
             WHEN zoom_level = 6 THEN geom_z6 && bbox
             WHEN zoom_level = 7 THEN geom_z7 && bbox
             WHEN zoom_level = 8 THEN geom_z8 && bbox
             WHEN zoom_level = 9 THEN geom_z9 && bbox
             WHEN zoom_level = 10 THEN geom_z10 && bbox
             WHEN zoom_level = 11 THEN geom_z11 && bbox
             WHEN zoom_level = 12 THEN geom_z12 && bbox
             WHEN zoom_level = 13 THEN geom_z13 && bbox
             WHEN zoom_level >= 14 THEN geometry && bbox
             ELSE FALSE
           END

         UNION ALL

         -- etldoc: osm_park_polygon_geometry -> layer_park:z4
         SELECT NULL::int AS osm_id,
                geometry,
                '{}'::jsonb AS attr,
                NULL::int AS rank
         FROM osm_park_polygon_dissolve_z4
         WHERE zoom_level = 4
           AND geometry && bbox

         UNION ALL
         SELECT osm_id,
                centroid AS geometry,
                attr,
                row_number() OVER (
                    PARTITION BY LabelGrid(centroid, 100 * pixel_width)
                    ORDER BY
                       (CASE WHEN attr->>'class' = 'national_park' THEN TRUE ELSE FALSE END) DESC,
                        (COALESCE(NULLIF(wikipedia, ''), NULLIF(wikidata, '')) IS NOT NULL) DESC,
                        area DESC
                    )::int AS rank
         FROM (
                  -- etldoc: osm_park_polygon_gen_z5 -> layer_park:z5
                  SELECT osm_id,
                         centroid,
                         wikipedia,
                         wikidata,
                         area,
                         attr
                  FROM osm_park_polygon_geometry
                  WHERE (
                      (zoom_level = 5 AND geom_z5 IS NOT NULL) OR
                      (zoom_level = 6 AND geom_z6 IS NOT NULL) OR
                      (zoom_level = 7 AND geom_z7 IS NOT NULL) OR
                      (zoom_level = 8 AND geom_z8 IS NOT NULL) OR
                      (zoom_level = 9 AND geom_z9 IS NOT NULL) OR
                      (zoom_level = 10 AND geom_z10 IS NOT NULL) OR
                      (zoom_level = 11 AND geom_z11 IS NOT NULL) OR
                      (zoom_level = 12 AND geom_z12 IS NOT NULL) OR
                      (zoom_level = 13 AND geom_z13 IS NOT NULL) OR
                      (zoom_level >= 14 AND geometry IS NOT NULL)
                    )
                    AND centroid && bbox
                    AND area > 70000*2^(20-zoom_level)
              ) AS park_point
     ) AS park_all;
$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;
-- TODO: Check if the above can be made STRICT -- i.e. if pixel_width could be NULL
