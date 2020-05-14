DROP TRIGGER IF EXISTS trigger_store_transportation_route_member ON osm_route_member;
DROP TRIGGER IF EXISTS trigger_store_transportation_highway_linestring ON osm_highway_linestring;
DROP TRIGGER IF EXISTS trigger_flag_transportation_name ON transportation_name.network_changes;
DROP TRIGGER IF EXISTS trigger_refresh_network ON transportation_name.updates_network;

DROP MATERIALIZED VIEW IF EXISTS osm_transportation_name_linestring_gen1 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_name_linestring_gen2 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_name_linestring_gen3 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_name_linestring_gen4 CASCADE;

DO
$$
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'route_network_type') THEN
            CREATE TYPE route_network_type AS enum (
                'us-interstate', 'us-highway', 'us-state',
                'ca-transcanada',
                'gb-motorway', 'gb-trunk'
                );
        END IF;
    END
$$;

DO
$$
    BEGIN
        BEGIN
            ALTER TABLE osm_route_member
                ADD COLUMN network_type route_network_type;
        EXCEPTION
            WHEN duplicate_column THEN RAISE NOTICE 'column network_type already exists in network_type.';
        END;
    END;
$$;
