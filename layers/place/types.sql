DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'city_class') THEN
		CREATE TYPE city_class AS ENUM ('city', 'town', 'village', 'hamlet', 'suburb', 'neighbourhood', 'isolated_dwelling');
    END IF;
END
$$;

ALTER TABLE osm_city_point ALTER COLUMN place TYPE city_class USING place::city_class;
