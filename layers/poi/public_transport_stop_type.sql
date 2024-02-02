DO
$$
    BEGIN
        PERFORM 'public_transport_stop_type'::regtype;
    EXCEPTION
        WHEN undefined_object THEN
            CREATE TYPE public_transport_stop_type AS enum (
                'subway', 'tram_stop', 'bus_station', 'bus_stop'
                );
    END
$$;
