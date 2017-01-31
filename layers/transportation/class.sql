CREATE SCHEMA IF NOT EXISTS transportation;

CREATE OR REPLACE FUNCTION transportation.brunnel(is_bridge BOOL, is_tunnel BOOL, is_ford BOOL) RETURNS TEXT AS $$
    SELECT CASE
        WHEN is_bridge THEN 'bridge'
        WHEN is_tunnel THEN 'tunnel'
        WHEN is_ford THEN 'ford'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- The classes for highways are derived from the classes used in ClearTables
-- https://github.com/ClearTables/ClearTables/blob/master/transportation.lua
CREATE OR REPLACE FUNCTION transportation.highway_class(highway TEXT) RETURNS TEXT AS $$
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

-- The classes for railways are derived from the classes used in ClearTables
-- https://github.com/ClearTables/ClearTables/blob/master/transportation.lua
CREATE OR REPLACE FUNCTION transportation.railway_class(railway TEXT) RETURNS TEXT AS $$
    SELECT CASE
        WHEN railway IN ('rail', 'narrow_gauge', 'preserved', 'funicular') THEN 'rail'
        WHEN railway IN ('subway', 'light_rail', 'monorail', 'tram') THEN 'transit'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- Limit service to only the most important values to ensure
-- we always know the values of service
CREATE OR REPLACE FUNCTION transportation.service_value(service TEXT) RETURNS TEXT AS $$
    SELECT CASE
        WHEN service IN ('spur', 'yard', 'siding', 'crossover', 'driveway', 'alley', 'parking_aisle') THEN service
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE STRICT;

-- Map Natural Earth types to OSM highway
CREATE OR REPLACE FUNCTION transportation.ne_highway(type VARCHAR) RETURNS VARCHAR AS $$
  SELECT CASE type
    WHEN 'Major Highway' THEN 'motorway'
    WHEN 'Secondary Highway' THEN 'trunk'
    WHEN 'Road' THEN 'primary'
    ELSE type
  END;
$$ LANGUAGE SQL IMMUTABLE;
