DROP TRIGGER IF EXISTS trigger_store_transportation_route_member ON osm_route_member;
DROP TRIGGER IF EXISTS trigger_store_transportation_highway_linestring ON osm_highway_linestring;
DROP TRIGGER IF EXISTS trigger_flag_transportation_name ON transportation_name.network_changes;
DROP TRIGGER IF EXISTS trigger_refresh_network ON transportation_name.updates_network;

DROP TRIGGER IF EXISTS trigger_store_transportation_name_network ON osm_transportation_name_network;
DROP TRIGGER IF EXISTS trigger_flag_name ON transportation_name.name_changes;
DROP TRIGGER IF EXISTS trigger_refresh_name ON transportation_name.updates_name;

DO
$$
    BEGIN
        PERFORM 'route_network_type'::regtype;
    EXCEPTION
        WHEN undefined_object THEN
            CREATE TYPE route_network_type AS enum (
                'us-interstate', 'us-highway', 'us-state',
                'ca-transcanada', 'ca-provincial-arterial', 'ca-provincial',
                'gb-motorway', 'gb-trunk', 'gb-primary',
                'ie-motorway', 'ie-national', 'ie-regional',
                'e-road',
                'a-road'
                );
    END
$$;

-- Top-level national route networks that should display at the lowest zooms
CREATE OR REPLACE FUNCTION osm_national_network(network text) RETURNS boolean AS
$$
    SELECT network <> '' AND network IN (
        -- Canada
        'ca-transcanada', 'ca-provincial-arterial',
        -- United States
        'us-interstate', 'us-highway',
        -- UK
        'gb-motorway', 'gb-trunk',
        -- Ireland
        'ie-motorway', 'ie-national',
        -- Europe
        'e-road',
        -- Asia
        'a-road'
    );
$$ LANGUAGE sql IMMUTABLE
                PARALLEL SAFE;

CREATE OR REPLACE FUNCTION create_route_hstore(network TEXT, ref TEXT, name TEXT, colour TEXT, ref_colour TEXT)
RETURNS hstore AS $$
SELECT CASE
           WHEN network = '' THEN hstore('')
           ELSE hstore(
               ARRAY['network', 'ref', 'name', 'colour'],
               ARRAY[network, NULLIF(ref, ''), NULLIF(name, ''), COALESCE(NULLIF(colour, ''), NULLIF(ref_colour, ''))]
           )
       END;
$$ LANGUAGE sql IMMUTABLE
    PARALLEL SAFE;
