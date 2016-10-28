DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'railway_properties') THEN
        CREATE TYPE railway_properties AS ENUM ('bridge', 'tunnel');
    END IF;
END
$$;

CREATE OR REPLACE FUNCTION to_railway_properties(is_bridge boolean, is_tunnel boolean) RETURNS railway_properties AS $$
    SELECT CASE
         WHEN is_bridge THEN 'bridge'::railway_properties
         WHEN is_tunnel THEN 'tunnel'::railway_properties
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;
