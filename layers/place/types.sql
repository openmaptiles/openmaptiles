DO
$$
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM pg_type WHERE typname = 'city_place') THEN
            CREATE TYPE city_place AS enum ('city', 'town', 'village', 'hamlet', 'suburb', 'quarter', 'neighbourhood', 'isolated_dwelling');
        END IF;
    END
$$;

ALTER TABLE osm_city_point
    ALTER COLUMN place TYPE city_place USING place::city_place;
