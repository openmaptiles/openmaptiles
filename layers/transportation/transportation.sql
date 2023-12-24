CREATE OR REPLACE FUNCTION highway_is_link(highway text) RETURNS boolean AS
$$
SELECT highway LIKE '%_link';
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;


-- etldoc: layer_transportation[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_transportation |<z4> z4 |<z5> z5 |<z6> z6 |<z7> z7 |<z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;
CREATE OR REPLACE FUNCTION layer_transportation(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                osm_id     bigint,
                geometry   geometry,
                class      text,
                subclass   text,
                network    text,
                ramp       int,
                oneway     int,
                brunnel    text,
                service    text,
                access     text,
                toll       int,
                expressway int,
                layer      int,
                level      int,
                indoor     int,
                bicycle    text,
                foot       text,
                horse      text,
                mtb_scale  text,
                surface    text
            )
AS
$$
SELECT osm_id,
       geometry,
       CASE
           WHEN highway <> '' OR public_transport <> ''
               THEN highway_class(highway, public_transport, construction)
           WHEN railway <> '' THEN railway_class(railway)
           WHEN aerialway <> '' THEN 'aerialway'
           WHEN shipway <> '' THEN shipway
           WHEN man_made <> '' THEN man_made
           END AS class,
       CASE
           WHEN railway IS NOT NULL THEN railway
           WHEN (highway IS NOT NULL OR public_transport IS NOT NULL)
               AND highway_class(highway, public_transport, construction) = 'path'
               THEN COALESCE(NULLIF(public_transport, ''), highway)
           WHEN aerialway IS NOT NULL THEN aerialway
           END AS subclass,
       NULLIF(network, '') AS network,
       -- All links are considered as ramps as well
       CASE
           WHEN highway_is_link(highway)
             OR is_ramp
               THEN 1 END AS ramp,
       CASE WHEN is_oneway <> 0 THEN is_oneway::int END AS oneway,
       brunnel(is_bridge, is_tunnel, is_ford) AS brunnel,
       NULLIF(service, '') AS service,
       access,
       CASE WHEN toll = TRUE THEN 1 END AS toll,
       CASE WHEN highway NOT IN ('', 'motorway') AND expressway = TRUE THEN 1 END AS expressway,
       NULLIF(layer, 0) AS layer,
       "level",
       CASE WHEN indoor = TRUE THEN 1 END AS indoor,
       NULLIF(bicycle, '') AS bicycle,
       NULLIF(foot, '') AS foot,
       NULLIF(horse, '') AS horse,
       NULLIF(mtb_scale, '') AS mtb_scale,
       NULLIF(surface, '') AS surface
FROM (
         -- etldoc: osm_transportation_merge_linestring_gen_z4 -> layer_transportation:z4
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z4
         WHERE zoom_level = 4
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z5 -> layer_transportation:z5
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z5
         WHERE zoom_level = 5
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z6 -> layer_transportation:z6
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z6
         WHERE zoom_level = 6
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z7  ->  layer_transportation:z7
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z7
         WHERE zoom_level = 7
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z8  ->  layer_transportation:z8
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                NULL AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z8
         WHERE zoom_level = 8
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z9  ->  layer_transportation:z9
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                access,
                toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                bicycle,
                foot,
                horse,
                mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z9
         WHERE zoom_level = 9
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z10  ->  layer_transportation:z10
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                access,
                toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                bicycle,
                foot,
                horse,
                mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z10
         WHERE zoom_level = 10
         UNION ALL

         -- etldoc: osm_transportation_merge_linestring_gen_z11  ->  layer_transportation:z11
         SELECT osm_id,
                geometry,
                highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                NULL AS service,
                access,
                toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                bicycle,
                foot,
                horse,
                mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_transportation_merge_linestring_gen_z11
         WHERE zoom_level = 11
         UNION ALL

         -- etldoc: osm_highway_linestring  ->  layer_transportation:z12
         -- etldoc: osm_highway_linestring  ->  layer_transportation:z13
         -- etldoc: osm_highway_linestring  ->  layer_transportation:z14_
         -- etldoc: osm_transportation_name_network  ->  layer_transportation:z12
         -- etldoc: osm_transportation_name_network  ->  layer_transportation:z13
         -- etldoc: osm_transportation_name_network  ->  layer_transportation:z14_
         SELECT hl.osm_id,
                hl.geometry,
                hl.highway,
                construction,
                network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                public_transport,
                service_value(service) AS service,
                CASE WHEN access IN ('private', 'no') THEN 'no' END AS access,
                toll,
                is_bridge,
                is_tunnel,
                is_ford,
                expressway,
                is_ramp,
                is_oneway,
                man_made,
                hl.layer,
                CASE WHEN hl.highway IN ('footway', 'steps') THEN hl.level END AS level,
                CASE WHEN hl.highway IN ('footway', 'steps') THEN hl.indoor END AS indoor,
                bicycle,
                foot,
                horse,
                mtb_scale,
                surface_value(COALESCE(NULLIF(surface, ''), tracktype)) AS "surface",
                hl.z_order
         FROM osm_highway_linestring hl
         LEFT OUTER JOIN osm_transportation_name_network n ON hl.osm_id = n.osm_id
         WHERE NOT is_area
           AND
               CASE WHEN zoom_level = 12 THEN
                         CASE WHEN transportation_filter_z12(hl.highway, hl.construction) THEN TRUE
                              WHEN hl.highway IN ('track', 'path') THEN n.route_rank = 1
                         END
                    WHEN zoom_level = 13 THEN
                         CASE WHEN man_made='pier' THEN NOT ST_IsClosed(hl.geometry)
                              WHEN hl.highway IN ('track', 'path') THEN (hl.name <> ''
                                                                   OR n.route_rank BETWEEN 1 AND 2
                                                                   OR hl.sac_scale <> ''
                                                                   )
                              ELSE transportation_filter_z13(hl.highway, public_transport, hl.construction, service)
                         END
                    WHEN zoom_level >= 14 THEN
                         CASE WHEN man_made='pier' THEN NOT ST_IsClosed(hl.geometry)
                              ELSE TRUE
                         END
               END
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z8  ->  layer_transportation:z8
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                NULL::int AS layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring_gen_z8
         WHERE zoom_level = 8
           AND railway = 'rail'
           AND service = ''
           AND usage = 'main'
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z9  ->  layer_transportation:z9
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                NULL::boolean AS is_bridge,
                NULL::boolean AS is_tunnel,
                NULL::boolean AS is_ford,
                NULL::boolean AS expressway,
                NULL::boolean AS is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring_gen_z9
         WHERE zoom_level = 9
           AND railway = 'rail'
           AND service = ''
           AND usage = 'main'
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z10  ->  layer_transportation:z10
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring_gen_z10
         WHERE zoom_level = 10
           AND railway IN ('rail', 'narrow_gauge')
           AND service = ''
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z11  ->  layer_transportation:z11
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring_gen_z11
         WHERE zoom_level = 11
           AND railway IN ('rail', 'narrow_gauge', 'light_rail')
           AND service = ''
         UNION ALL

         -- etldoc: osm_railway_linestring_gen_z12  ->  layer_transportation:z12
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring_gen_z12
         WHERE zoom_level = 12
           AND railway IN ('rail', 'narrow_gauge', 'light_rail')
           AND service = ''
         UNION ALL

         -- etldoc: osm_railway_linestring ->  layer_transportation:z13
         -- etldoc: osm_railway_linestring ->  layer_transportation:z14_
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                railway,
                NULL AS aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_railway_linestring
         WHERE zoom_level = 13
           AND railway IN ('rail', 'narrow_gauge', 'light_rail')
           AND service = ''
           OR zoom_level >= 14
         UNION ALL

         -- etldoc: osm_aerialway_linestring_gen_z12  ->  layer_transportation:z12
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_aerialway_linestring_gen_z12
         WHERE zoom_level = 12
         UNION ALL

         -- etldoc: osm_aerialway_linestring ->  layer_transportation:z13
         -- etldoc: osm_aerialway_linestring ->  layer_transportation:z14_
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                aerialway,
                NULL AS shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_aerialway_linestring
         WHERE zoom_level >= 13
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z4  ->  layer_transportation:z4
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z4
         WHERE zoom_level = 4
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z5  ->  layer_transportation:z5
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z5
         WHERE zoom_level = 5
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z6  ->  layer_transportation:z6
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z6
         WHERE zoom_level = 6
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z7  ->  layer_transportation:z7
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z7
         WHERE zoom_level = 7
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z8  ->  layer_transportation:z8
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z8
         WHERE zoom_level = 8
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z9  ->  layer_transportation:z9
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z9
         WHERE zoom_level = 9
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z10  ->  layer_transportation:z10
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z10
         WHERE zoom_level = 10
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z11  ->  layer_transportation:z11
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z11
         WHERE zoom_level = 11
         UNION ALL

         -- etldoc: osm_shipway_linestring_gen_z12  ->  layer_transportation:z12
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring_gen_z12
         WHERE zoom_level = 12
         UNION ALL

         -- etldoc: osm_shipway_linestring ->  layer_transportation:z13
         -- etldoc: osm_shipway_linestring ->  layer_transportation:z14_
         SELECT osm_id,
                geometry,
                NULL AS highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                shipway,
                NULL AS public_transport,
                service_value(service) AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                is_bridge,
                is_tunnel,
                is_ford,
                NULL::boolean AS expressway,
                is_ramp,
                NULL::int AS is_oneway,
                NULL AS man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_shipway_linestring
         WHERE zoom_level >= 13
         UNION ALL

         -- NOTE: We limit the selection of polys because we need to be
         -- careful to net get false positives here because
         -- it is possible that closed linestrings appear both as
         -- highway linestrings and as polygon
         -- etldoc: osm_highway_polygon ->  layer_transportation:z13
         -- etldoc: osm_highway_polygon ->  layer_transportation:z14_
         SELECT osm_id,
                geometry,
                highway,
                NULL AS construction,
                NULL AS network,
                NULL AS railway,
                NULL AS aerialway,
                NULL AS shipway,
                public_transport,
                NULL AS service,
                NULL::text AS access,
                NULL::boolean AS toll,
                CASE
                    WHEN man_made IN ('bridge') THEN TRUE
                    ELSE FALSE
                    END AS is_bridge,
                FALSE AS is_tunnel,
                FALSE AS is_ford,
                NULL::boolean AS expressway,
                FALSE AS is_ramp,
                FALSE::int AS is_oneway,
                man_made,
                layer,
                NULL::int AS level,
                NULL::boolean AS indoor,
                NULL AS bicycle,
                NULL AS foot,
                NULL AS horse,
                NULL AS mtb_scale,
                NULL AS surface,
                z_order
         FROM osm_highway_polygon
              -- We do not want underground pedestrian areas for now
         WHERE zoom_level >= 13
           AND (
                 man_made IN ('bridge', 'pier')
                 OR (is_area AND COALESCE(layer, 0) >= 0)
             )
     ) AS zoom_levels
WHERE geometry && bbox
ORDER BY z_order ASC;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
