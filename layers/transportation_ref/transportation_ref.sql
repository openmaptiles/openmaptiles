-- etldoc: layer_transportation_ref[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_transportation_ref | <z6> z6 | <z7> z7 | <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_transportation_ref(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                geometry   geometry,
                class      text,
                subclass   text,
                network    text,
                network_1  text,
                network_2  text,
                network_3  text,
                network_4  text,
                network_5  text,
                network_6  text,
                ref_1      text,
                ref_2      text,
                ref_3      text,
                ref_4      text,
                ref_5      text,
                ref_6      text
            )
AS
$$
SELECT geometry,
       highway_class(highway, '', subclass) AS class,
       CASE
           WHEN highway IS NOT NULL AND highway_class(highway, '', subclass) = 'path'
               THEN highway
           ELSE subclass
           END AS subclass,
       CASE
           WHEN network IS NOT NULL
               THEN network::text
           WHEN length(coalesce(ref_1, '')) > 0
               THEN 'road'
           END AS network,
       network_1, network_2, network_3, network_4, network_5, network_6,
       ref_1,     ref_2,     ref_3,     ref_4,     ref_5,     ref_6
FROM (
         -- etldoc: osm_transportation_ref_linestring_gen4 ->  layer_transportation_ref:z6
         SELECT *
         FROM osm_transportation_ref_linestring_gen4
         WHERE zoom_level = 6
         UNION ALL

         -- etldoc: osm_transportation_ref_linestring_gen3 ->  layer_transportation_ref:z7
         SELECT *
         FROM osm_transportation_ref_linestring_gen3
         WHERE zoom_level = 7
         UNION ALL

         -- etldoc: osm_transportation_ref_linestring_gen2 ->  layer_transportation_ref:z8
         SELECT *
         FROM osm_transportation_ref_linestring_gen2
         WHERE zoom_level = 8
         UNION ALL

         -- etldoc: osm_transportation_ref_linestring_gen1 ->  layer_transportation_ref:z9
         -- etldoc: osm_transportation_ref_linestring_gen1 ->  layer_transportation_ref:z10
         -- etldoc: osm_transportation_ref_linestring_gen1 ->  layer_transportation_ref:z11
         SELECT *
         FROM osm_transportation_ref_linestring_gen1
         WHERE zoom_level BETWEEN 9 AND 11
         UNION ALL

         -- etldoc: osm_transportation_ref_linestring ->  layer_transportation_ref:z12
         SELECT *
         FROM osm_transportation_ref_linestring
         WHERE zoom_level = 12
           AND highway_class(highway, '', subclass) NOT IN ('minor', 'track', 'path')
           AND NOT highway_is_link(highway)
         UNION ALL

         -- etldoc: osm_transportation_ref_linestring ->  layer_transportation_ref:z13
         SELECT *
         FROM osm_transportation_ref_linestring
         WHERE zoom_level = 13
           AND highway_class(highway, '', subclass) NOT IN ('track', 'path')
         UNION ALL

         -- etldoc: osm_transportation_ref_linestring ->  layer_transportation_ref:z14_
         SELECT *
         FROM osm_transportation_ref_linestring
         WHERE zoom_level >= 14

     ) AS zoom_levels
WHERE geometry && bbox
ORDER BY z_order ASC;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
