-- etldoc: layer_transportation_name[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_transportation_name | <z6> z6 | <z7> z7 | <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_transportation_name(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                geometry        geometry,
                name            text,
                name_en         text,
                name_de         text,
                tags            hstore,
                ref             text,
                ref_length      int,
                network         text,
                route_1_network text,
                route_1_ref     text,
                route_1_name    text,
                route_1_colour  text,
                route_2_network text,
                route_2_ref     text,
                route_2_name    text,
                route_2_colour  text,
                route_3_network text,
                route_3_ref     text,
                route_3_name    text,
                route_3_colour  text,
                route_4_network text,
                route_4_ref     text,
                route_4_name    text,
                route_4_colour  text,
                route_5_network text,
                route_5_ref     text,
                route_5_name    text,
                route_5_colour  text,
                route_6_network text,
                route_6_ref     text,
                route_6_name    text,
                route_6_colour  text,
                class           text,
                subclass        text,
                brunnel         text,
                layer           int,
                level           int,
                indoor          int
            )
AS
$$
SELECT geometry,
       tags->'name' AS name,
       COALESCE(tags->'name:en', tags->'name') AS name_en,
       COALESCE(tags->'name:de', tags->'name', tags->'name:en') AS name_de,
       tags,
       ref,
       NULLIF(LENGTH(ref), 0) AS ref_length,
       CASE
           WHEN network IS NOT NULL
               THEN network::text
           WHEN length(coalesce(ref, '')) > 0
               THEN 'road'
           END AS network,
       route_1->'network' AS route_1_network,
       route_1->'ref' AS route_1_ref,
       route_1->'name' AS route_1_name,
       route_1->'colour' AS route_1_colour,

       route_2->'network' AS route_2_network,
       route_2->'ref' AS route_2_ref,
       route_2->'name' AS route_2_name,
       route_2->'colour' AS route_2_colour,

       route_3->'network' AS route_3_network,
       route_3->'ref' AS route_3_ref,
       route_3->'name' AS route_3_name,
       route_3->'colour' AS route_3_colour,

       route_4->'network' AS route_4_network,
       route_4->'ref' AS route_4_ref,
       route_4->'name' AS route_4_name,
       route_4->'colour' AS route_4_colour,

       route_5->'network' AS route_5_network,
       route_5->'ref' AS route_5_ref,
       route_5->'name' AS route_5_name,
       route_5->'colour' AS route_5_colour,

       route_6->'network' AS route_6_network,
       route_6->'ref' AS route_6_ref,
       route_6->'name' AS route_6_name,
       route_6->'colour' AS route_6_colour,
       highway_class(highway, '', subclass) AS class,
       CASE
           WHEN highway IS NOT NULL AND highway_class(highway, '', subclass) = 'path'
               THEN highway
           ELSE subclass
           END AS subclass,
       NULLIF(brunnel, '') AS brunnel,
       NULLIF(layer, 0) AS layer,
       "level",
       CASE WHEN indoor = TRUE THEN 1 END AS indoor
FROM (

         -- etldoc: osm_transportation_name_linestring_gen4 ->  layer_transportation_name:z6
         SELECT geometry,
                tags,
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1,
                route_2,
                route_3,
                route_4,
                route_5,
                route_6,
                z_order,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor
         FROM osm_transportation_name_linestring_gen4
         WHERE zoom_level = 6
         UNION ALL

         -- etldoc: osm_transportation_name_linestring_gen3 ->  layer_transportation_name:z7
         SELECT geometry,
                tags,
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1,
                route_2,
                route_3,
                route_4,
                route_5,
                route_6,
                z_order,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor
         FROM osm_transportation_name_linestring_gen3
         WHERE ST_Length(geometry) > 20000 AND zoom_level = 7
         UNION ALL

         -- etldoc: osm_transportation_name_linestring_gen2 ->  layer_transportation_name:z8
         SELECT geometry,
                tags,
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1,
                route_2,
                route_3,
                route_4,
                route_5,
                route_6,
                z_order,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor
         FROM osm_transportation_name_linestring_gen2
         WHERE ST_Length(geometry) > 14000 AND zoom_level = 8
         UNION ALL

         -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z9
         -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z10
         -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z11
         SELECT geometry,
                tags,
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1,
                route_2,
                route_3,
                route_4,
                route_5,
                route_6,
                z_order,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor
         FROM osm_transportation_name_linestring_gen1
         WHERE ST_Length(geometry) > 8000 / POWER(2, zoom_level - 9) AND zoom_level BETWEEN 9 AND 11
         UNION ALL

         -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z12
         SELECT geometry,
                "tags",
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1, route_2, route_3, route_4, route_5, route_6,
                z_order,
                layer,
                "level",
                indoor
         FROM osm_transportation_name_linestring
         WHERE zoom_level = 12
           AND LineLabel(zoom_level, COALESCE(ref, tags->'name'), geometry)
           AND NOT highway_is_link(highway)
           AND
               CASE WHEN highway_class(highway, NULL::text, NULL::text) NOT IN ('path', 'minor') THEN TRUE
                    WHEN highway IN ('aerialway', 'unclassified', 'residential', 'shipway') THEN TRUE
                    WHEN route_rank = 1 THEN TRUE END

         UNION ALL

         -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z13
         SELECT geometry,
                "tags",
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1, route_2, route_3, route_4, route_5, route_6,
                z_order,
                layer,
                "level",
                indoor
         FROM osm_transportation_name_linestring
         WHERE zoom_level = 13
           AND LineLabel(zoom_level, COALESCE(ref, tags->'name'), geometry)
           AND
               CASE WHEN highway <> 'path' THEN TRUE
                    WHEN highway = 'path' AND (
                                                   tags->'name' <> ''
                                                OR network IS NOT NULL
                                                OR sac_scale <> ''
                                                OR route_rank <= 2
                                              ) THEN TRUE
               END

         UNION ALL

         -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z14_
         SELECT geometry,
                "tags",
                ref,
                highway,
                subclass,
                brunnel,
                network,
                route_1, route_2, route_3, route_4, route_5, route_6,
                z_order,
                layer,
                "level",
                indoor
         FROM osm_transportation_name_linestring
         WHERE zoom_level >= 14
         UNION ALL

         -- etldoc: osm_highway_point ->  layer_transportation_name:z10
         SELECT
		p.geometry,
                p.tags,
                p.ref,
                (
                  SELECT highest_highway(l.tags->'highway')
                    FROM osm_highway_linestring l
                    WHERE ST_Intersects(p.geometry,l.geometry)
                ) AS class,
                'junction'::text AS subclass,
                NULL AS brunnel,
                NULL AS network,
                NULL::hstore AS route_1,
                NULL::hstore AS route_2,
                NULL::hstore AS route_3,
                NULL::hstore AS route_4,
                NULL::hstore AS route_5,
                NULL::hstore AS route_6,
                z_order,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor
         FROM osm_highway_point p
         WHERE highway = 'motorway_junction' AND zoom_level >= 10
     ) AS zoom_levels
WHERE geometry && bbox
ORDER BY z_order ASC;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
