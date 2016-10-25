DROP TYPE IF EXISTS highway_class CASCADE;
CREATE TYPE highway_class AS ENUM ('motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'minor_road', 'path');

DROP TYPE IF EXISTS highway_properties CASCADE;
CREATE TYPE highway_properties AS ENUM ('bridge:oneway', 'tunnel:oneway', 'ramp', 'ford', 'bridge', 'tunnel', 'oneway');

CREATE OR REPLACE FUNCTION to_highway_class(highway TEXT) RETURNS highway_class AS $$
    SELECT CASE
        WHEN highway IN ('motorway', 'motorway_link') THEN 'motorway'::highway_class
        WHEN highway IN ('trunk', 'trunk_link') THEN 'trunk'::highway_class
        WHEN highway IN ('primary', 'primary_link') THEN 'primary'::highway_class
        WHEN highway IN ('secondary', 'secondary_link') THEN 'secondary'::highway_class
        WHEN highway IN ('tertiary', 'tertiary_link') THEN 'tertiary'::highway_class
        WHEN highway IN ('unclassified', 'residential', 'living_street', 'road', 'track', 'service') THEN 'minor_road'::highway_class
        WHEN highway IN ('pedestrian', 'path', 'footway', 'cycleway', 'steps') THEN 'path'::highway_class
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

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
$$ LANGUAGE SQL IMMUTABLE STRICT;
