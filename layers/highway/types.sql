

-- etldoc: types_sql[label="types.sql", shape=note ]

DO $$
-- etldoc: type_highway_class[label="TYPE highway_class"] 
-- etldoc: types_sql-> type_highway_class
-- etldoc: type_highway_class -> postgreSQL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'highway_class') THEN
		CREATE TYPE highway_class AS ENUM ('motorway', 'major_road', 'minor_road', 'path');
    END IF;
END
$$;

DO $$
-- etldoc: type_highway_properties[label="TYPE highway_properties"] 
-- etldoc: types_sql-> type_highway_properties
-- etldoc: type_highway_properties -> postgreSQL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'highway_properties') THEN
        CREATE TYPE highway_properties AS ENUM ('bridge:oneway', 'tunnel:oneway', 'ramp', 'ford', 'bridge', 'tunnel', 'oneway');
    END IF;
END
$$;


-- etldoc: function_to_highway_class[label="FUNCTION to_highway_class"]
-- etldoc: types_sql-> function_to_highway_class 
-- etldoc: function_to_highway_class -> postgreSQL
CREATE OR REPLACE FUNCTION to_highway_class(highway TEXT) RETURNS highway_class AS $$
    SELECT CASE
        WHEN highway IN ('motorway', 'motorway_link') THEN 'motorway'::highway_class
        -- A major class is helpful in styling - one can still differentiate on a finer level using the subclass
        WHEN highway IN ('trunk', 'trunk_link',
                         'primary', 'primary_link',
                         'secondary', 'secondary_link',
                         'tertiary', 'tertiary_link') THEN 'major_road'::highway_class
        WHEN highway IN ('unclassified', 'residential', 'living_street', 'road', 'track', 'service') THEN 'minor_road'::highway_class
        WHEN highway IN ('pedestrian', 'path', 'footway', 'cycleway', 'steps') THEN 'path'::highway_class
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- etldoc: function_to_highway_properties[label="FUNCTION to_highway_properties"]
-- etldoc: types_sql-> function_to_highway_properties
-- etldoc: function_to_highway_properties -> postgreSQL
CREATE OR REPLACE FUNCTION to_highway_properties(is_bridge boolean, is_tunnel boolean, is_ford boolean, is_ramp boolean, is_oneway boolean) RETURNS highway_properties AS $$
    SELECT CASE
         WHEN is_bridge AND is_oneway THEN 'bridge:oneway'::highway_properties
         WHEN is_tunnel AND is_oneway THEN 'tunnel:oneway'::highway_properties
         WHEN is_ramp THEN 'ramp'::highway_properties
         WHEN is_ford THEN 'ford'::highway_properties
         WHEN is_bridge THEN 'bridge'::highway_properties
         WHEN is_tunnel THEN 'tunnel'::highway_properties
         WHEN is_oneway THEN 'oneway'::highway_properties
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;
