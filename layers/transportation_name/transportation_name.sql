-- etldoc: layer_transportation_name[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_transportation_name | <z6> z6 | <z7> z7 | <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_transportation_name(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                geometry   geometry,
                name       text,
                name_en    text,
                name_de    text,
                tags       hstore,
                ref        text,
                ref_length int,
                network    text,
                route_1    text,
                route_2    text,
                route_3    text,
                route_4    text,
                route_5    text,
                route_6    text,
                class      text,
                subclass   text,
                brunnel    text,
                layer      int,
                level      int,
                indoor     int
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
       route_1, route_2, route_3, route_4, route_5, route_6,
       highway_class(highway, '', subclass) AS class,
       CASE
           WHEN highway IS NOT NULL AND highway_class(highway, '', subclass) = 'path'
               THEN highway
           ELSE subclass
           END AS subclass,
       brunnel,
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
           AND LineLabel(zoom_level, COALESCE(tags->'name', ref), geometry)
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
           AND LineLabel(zoom_level, COALESCE(tags->'name', ref), geometry)
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
                NULL::text AS route_1,
                NULL::text AS route_2,
                NULL::text AS route_3,
                NULL::text AS route_4,
                NULL::text AS route_5,
                NULL::text AS route_6,
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
