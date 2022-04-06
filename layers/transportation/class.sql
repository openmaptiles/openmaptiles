CREATE OR REPLACE FUNCTION brunnel(is_bridge bool, is_tunnel bool, is_ford bool) RETURNS text AS
$$
SELECT CASE
           WHEN is_bridge THEN 'bridge'
           WHEN is_tunnel THEN 'tunnel'
           WHEN is_ford THEN 'ford'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- The classes for highways are derived from the classes used in ClearTables
-- https://github.com/ClearTables/ClearTables/blob/master/transportation.lua
CREATE OR REPLACE FUNCTION highway_class(highway text, public_transport text, construction text) RETURNS text AS
$$
SELECT CASE
           %%FIELD_MAPPING: class %%
           END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

-- The classes for railways are derived from the classes used in ClearTables
-- https://github.com/ClearTables/ClearTables/blob/master/transportation.lua
CREATE OR REPLACE FUNCTION railway_class(railway text) RETURNS text AS
$$
SELECT CASE
           WHEN railway IN ('rail', 'narrow_gauge', 'preserved', 'funicular') THEN 'rail'
           WHEN railway IN ('subway', 'light_rail', 'monorail', 'tram') THEN 'transit'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Limit service to only the most important values to ensure
-- we always know the values of service
CREATE OR REPLACE FUNCTION service_value(service text) RETURNS text AS
$$
SELECT CASE
           WHEN service IN ('spur', 'yard', 'siding', 'crossover', 'driveway', 'alley', 'parking_aisle') THEN service
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Limit surface to only the most important values to ensure
-- we always know the values of surface
CREATE OR REPLACE FUNCTION surface_value(surface text) RETURNS text AS
$$
SELECT CASE
           WHEN surface IN ('paved', 'asphalt', 'cobblestone', 'concrete', 'concrete:lanes', 'concrete:plates', 'metal',
                            'paving_stones', 'sett', 'unhewn_cobblestone', 'wood') THEN 'paved'
           WHEN surface IN ('unpaved', 'compacted', 'dirt', 'earth', 'fine_gravel', 'grass', 'grass_paver', 'gravel',
                            'gravel_turf', 'ground', 'ice', 'mud', 'pebblestone', 'salt', 'sand', 'snow', 'woodchips')
               THEN 'unpaved'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Determine which transportation features are shown at zoom 12
CREATE OR REPLACE FUNCTION transportation_filter_z12(highway text, construction text) RETURNS boolean AS
$$
SELECT CASE
           WHEN highway IN ('unclassified', 'residential') THEN TRUE
           WHEN highway_class(highway, '', construction) IN
               (
                'motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'raceway',
                'motorway_construction', 'trunk_construction', 'primary_construction',
                'secondary_construction', 'tertiary_construction', 'raceway_construction',
                'busway'
               ) THEN TRUE --includes ramps
           ELSE FALSE
       END
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- Determine which transportation features are shown at zoom 13
-- Assumes that piers have already been excluded
CREATE OR REPLACE FUNCTION transportation_filter_z13(highway text,
                                                     public_transport text,
                                                     construction text,
                                                     service text) RETURNS boolean AS
$$
SELECT CASE
           WHEN transportation_filter_z12(highway, construction) THEN TRUE
           WHEN highway = 'service' OR construction = 'service' THEN service NOT IN ('driveway', 'parking_aisle')
           WHEN highway_class(highway, public_transport, construction) IN ('minor', 'minor_construction') THEN TRUE
           ELSE FALSE
       END
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- returns the highest speed
CREATE OR REPLACE FUNCTION maxspeed_all(maxspeed int, maxspeed_forward int, maxspeed_backward int) RETURNS int AS
$$
SELECT GREATEST(maxspeed, maxspeed_forward, maxspeed_backward);
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

-- returns combination of all signs
CREATE OR REPLACE FUNCTION traffic_sign_all(traffic_sign text, traffic_sign_forward text, traffic_sign_backward text) RETURNS text AS
$$
SELECT concat_ws(';', NULLIF(traffic_sign,''), NULLIF(traffic_sign_forward,''), NULLIF(traffic_sign_backward,''));
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

CREATE OR REPLACE FUNCTION bicycle_all(bicycle text, 
                                    bicycle_forward text, bicycle_backward text,
                                    sidewalk_bicycle text, sidewalk_both_bicycle text,
                                    sidewalk_left_bicycle text,sidewalk_right_bicycle text)
                            RETURNS text AS
$$
SELECT CASE
           WHEN bicycle = 'no' OR bicycle_forward = 'no' OR bicycle_backward = 'no' THEN 'no'
           WHEN bicycle = 'use_sidepath' OR bicycle_forward = 'use_sidepath' OR bicycle_backward = 'use_sidepath' THEN 'use_sidepath'
           WHEN bicycle = 'optional_sidepath' OR bicycle_forward = 'optional_sidepath' OR bicycle_backward = 'optional_sidepath' OR 
                sidewalk_bicycle = 'yes' OR sidewalk_both_bicycle = 'yes' OR sidewalk_left_bicycle = 'yes' OR sidewalk_right_bicycle = 'yes' -- is a usable sidewalk? than it's a optional track
             THEN 'optional_sidepath'
           ELSE COALESCE(NULLIF(bicycle,''),NULLIF(bicycle_forward,''),NULLIF(bicycle_backward,''))
       END
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

CREATE OR REPLACE FUNCTION cycleway_all(cycleway text, cycleway_both text, 
                                        cycleway_left text, cycleway_right text,
                                        sidewalk_bicycle text, sidewalk_both_bicycle text,
                                        sidewalk_left_bicycle text,sidewalk_right_bicycle text) 
                            RETURNS text AS
$$
SELECT CASE
           WHEN cycleway = 'no' OR cycleway_both = 'no' OR cycleway_left = 'no' OR cycleway_right = 'no' THEN 'no'
           WHEN cycleway = 'separate' OR cycleway_both = 'separate' OR cycleway_left = 'separate' OR cycleway_right = 'separate' THEN 'separate'
           WHEN cycleway = 'track' OR cycleway_both = 'track' OR cycleway_left = 'track' OR cycleway_right = 'track' OR
                sidewalk_bicycle = 'yes' OR sidewalk_both_bicycle = 'yes' OR sidewalk_left_bicycle = 'yes' OR sidewalk_right_bicycle = 'yes' -- is a usable sidewalk? than it's a optional track
             THEN 'track'
           ELSE COALESCE(NULLIF(cycleway,''),NULLIF(cycleway_both,''),NULLIF(cycleway_left,''),NULLIF(cycleway_right,''))
       END
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;