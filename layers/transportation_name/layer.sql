
-- etldoc: layer_transportation_name[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_transportation_name | <z6> z6 | <z7> z7 | <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_transportation_name(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text,
  name_de text, tags hstore, ref text, ref_length int, network text, class
  text, subclass text, layer INT, level INT, indoor INT) AS $$
    SELECT osm_id, geometry,
      NULLIF(name, '') AS name,
      COALESCE(NULLIF(name_en, ''), name) AS name_en,
      COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
      tags,
      NULLIF(ref, ''), NULLIF(LENGTH(ref), 0) AS ref_length,
      --TODO: The road network of the road is not yet implemented
      case
        when network is not null
          then network::text
        when length(coalesce(ref, ''))>0
          then 'road'
      end as network,
      highway_class(highway, '', construction) AS class,
      CASE
          WHEN highway IS NOT NULL AND highway_class(highway, '', construction) = 'path'
              THEN highway
      END AS subclass,
      NULLIF(layer, 0) AS layer,
      "level",
      CASE WHEN indoor=TRUE THEN 1 END as indoor
    FROM (

        -- etldoc: osm_transportation_name_linestring_gen4 ->  layer_transportation_name:z6
        SELECT *,
            NULL::int AS layer, NULL::int AS level, NULL::boolean AS indoor
        FROM osm_transportation_name_linestring_gen4
        WHERE zoom_level = 6
        UNION ALL

        -- etldoc: osm_transportation_name_linestring_gen3 ->  layer_transportation_name:z7
        SELECT *,
            NULL::int AS layer, NULL::int AS level, NULL::boolean AS indoor
        FROM osm_transportation_name_linestring_gen3
        WHERE zoom_level = 7
        UNION ALL

        -- etldoc: osm_transportation_name_linestring_gen2 ->  layer_transportation_name:z8
        SELECT *,
            NULL::int AS layer, NULL::int AS level, NULL::boolean AS indoor
        FROM osm_transportation_name_linestring_gen2
        WHERE zoom_level = 8
        UNION ALL

        -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z9
        -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z10
        -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z11
        SELECT *,
            NULL::int AS layer, NULL::int AS level, NULL::boolean AS indoor
        FROM osm_transportation_name_linestring_gen1
        WHERE zoom_level BETWEEN 9 AND 11
        UNION ALL

        -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z12
        SELECT
          geometry,
          osm_id,
          name,
          name_en,
          name_de,
          "tags",
          ref,
          highway,
          construction,
          network,
          z_order,
          layer,
          "level",
          indoor
        FROM osm_transportation_name_linestring
        WHERE zoom_level = 12
            AND LineLabel(zoom_level, COALESCE(NULLIF(name, ''), ref), geometry)
            AND highway_class(highway, '', construction) NOT IN ('minor', 'track', 'path')
            AND NOT highway_is_link(highway)
        UNION ALL

        -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z13
        SELECT
          geometry,
          osm_id,
          name,
          name_en,
          name_de,
          "tags",
          ref,
          highway,
          construction,
          network,
          z_order,
          layer,
          "level",
          indoor
        FROM osm_transportation_name_linestring
        WHERE zoom_level = 13
            AND LineLabel(zoom_level, COALESCE(NULLIF(name, ''), ref), geometry)
            AND highway_class(highway, '', construction) NOT IN ('track', 'path')
        UNION ALL

        -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z14_
        SELECT
          geometry,
          osm_id,
          name,
          name_en,
          name_de,
          "tags",
          ref,
          highway,
          construction,
          network,
          z_order,
          layer,
          "level",
          indoor
        FROM osm_transportation_name_linestring
        WHERE zoom_level >= 14

    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;
