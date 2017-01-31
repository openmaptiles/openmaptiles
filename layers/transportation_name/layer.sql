
-- etldoc: layer_transportation_name[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_transportation_name | <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13|<z14_> z14+" ] ;

-- The classes for highways are derived from the classes used in ClearTables
-- https://github.com/ClearTables/ClearTables/blob/master/transportation.lua
CREATE OR REPLACE FUNCTION transportation_name.highway_class(highway TEXT) RETURNS TEXT AS $$
    SELECT CASE
        WHEN highway IN ('motorway', 'motorway_link') THEN 'motorway'
        WHEN highway IN ('trunk', 'trunk_link') THEN 'trunk'
        WHEN highway IN ('primary', 'primary_link') THEN 'primary'
        WHEN highway IN ('secondary', 'secondary_link') THEN 'secondary'
        WHEN highway IN ('tertiary', 'tertiary_link') THEN 'tertiary'
        WHEN highway IN ('unclassified', 'residential', 'living_street', 'road') THEN 'minor'
        WHEN highway IN ('service', 'track') THEN highway
        WHEN highway IN ('pedestrian', 'path', 'footway', 'cycleway', 'steps', 'bridleway', 'corridor') THEN 'path'
        WHEN highway = 'raceway' THEN 'raceway'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION transportation_name.highway_is_link(highway TEXT) RETURNS BOOLEAN AS $$
    SELECT highway LIKE '%_link';
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION transportation_name.layer_transportation_name(bbox geometry, zoom_level integer)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, ref text, ref_length int, network text, class text) AS $$
    SELECT osm_id, geometry,
      NULLIF(name, '') AS name,
      COALESCE(NULLIF(name_en, ''), NULLIF(name, '')) AS name_en,
      NULLIF(ref, ''), NULLIF(LENGTH(ref), 0) AS ref_length,
      --TODO: The road network of the road is not yet implemented
      NULL::text AS network,
      transportation_name.highway_class(highway) AS class
    FROM (

        -- etldoc: osm_transportation_name_linestring_gen3 ->  layer_transportation_name:z8
        SELECT * FROM transportation_name.osm_transportation_name_linestring_gen3
        WHERE zoom_level = 8
        UNION ALL

        -- etldoc: osm_transportation_name_linestring_gen2 ->  layer_transportation_name:z9
        SELECT * FROM transportation_name.osm_transportation_name_linestring_gen2
        WHERE zoom_level = 9
        UNION ALL

        -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z10
        -- etldoc: osm_transportation_name_linestring_gen1 ->  layer_transportation_name:z11
        SELECT * FROM transportation_name.osm_transportation_name_linestring_gen1
        WHERE zoom_level BETWEEN 10 AND 11
        UNION ALL

        -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z12
        SELECT * FROM transportation_name.osm_transportation_name_linestring
        WHERE zoom_level = 12
            AND LineLabel(zoom_level, COALESCE(NULLIF(name, ''), ref), geometry)
            AND transportation_name.highway_class(highway) NOT IN ('minor', 'track', 'path')
            AND NOT transportation_name.highway_is_link(highway)
        UNION ALL

        -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z13
        SELECT * FROM transportation_name.osm_transportation_name_linestring
        WHERE zoom_level = 13
            AND LineLabel(zoom_level, COALESCE(NULLIF(name, ''), ref), geometry)
            AND transportation_name.highway_class(highway) NOT IN ('track', 'path')
        UNION ALL

        -- etldoc: osm_transportation_name_linestring ->  layer_transportation_name:z14_
        SELECT * FROM transportation_name.osm_transportation_name_linestring
        WHERE zoom_level >= 14

    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION transportation_name.delete() RETURNS VOID AS $$
BEGIN
  DROP TRIGGER IF EXISTS trigger_flag ON osm_highway_linestring;
  DROP TRIGGER IF EXISTS trigger_refresh ON transportation_name.updates;
  DROP SCHEMA IF EXISTS transportation_name CASCADE;
END;
$$ LANGUAGE plpgsql;
