CREATE OR REPLACE FUNCTION to_brunnel(is_bridge BOOL, is_tunnel BOOL, is_ford BOOL) RETURNS TEXT AS $$
    SELECT CASE
        WHEN is_bridge THEN 'bridge'
        WHEN is_tunnel THEN 'tunnel'
        WHEN is_ford THEN 'ford'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION to_highway_class(highway TEXT) RETURNS TEXT AS $$
    SELECT CASE
        WHEN highway IN ('motorway', 'motorway_link') THEN 'motorway'
        -- A major class is helpful in styling - one can still differentiate on a finer level using the subclass
        WHEN highway IN ('trunk', 'trunk_link',
                         'primary', 'primary_link',
                         'secondary', 'secondary_link',
                         'tertiary', 'tertiary_link') THEN 'major_road'
        WHEN highway IN ('unclassified', 'residential', 'living_street', 'road', 'track', 'service') THEN 'minor_road'
        WHEN highway IN ('pedestrian', 'path', 'footway', 'cycleway', 'steps') THEN 'path'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION railway_class(railway text, service text) RETURNS TEXT AS $$
    SELECT CASE
        WHEN railway='rail' AND service='' THEN 'rail'
        ELSE 'minor_rail'
    END;
$$ LANGUAGE SQL IMMUTABLE;
