DO $$
BEGIN
    IF NOT EXISTS (SELECT 1
                   FROM pg_type
                   WHERE typname = 'public_transport_stop_type') THEN
        CREATE TYPE public_transport_stop_type AS ENUM (
          'subway', 'tram_stop', 'bus_station', 'bus_stop'
        );
    END IF;
END
$$;
