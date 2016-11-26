

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'highway_class') THEN
		CREATE TYPE highway_class AS ENUM ('motorway', 'major_road', 'minor_road', 'path');
    END IF;
END
$$;

CREATE OR REPLACE FUNCTION to_brunnel(is_bridge BOOL, is_tunnel BOOL, is_ford BOOL) RETURNS TEXT AS $$
    SELECT CASE
        WHEN is_bridge THEN 'bridge'
        WHEN is_tunnel THEN 'tunnel'
        WHEN is_ford THEN 'ford'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

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
