DO
$$
    BEGIN
        PERFORM 'city_place'::regtype;
    EXCEPTION
        WHEN undefined_object THEN
            CREATE TYPE city_place AS enum ('city', 'town', 'village', 'hamlet', 'borough', 'suburb', 'quarter', 'neighbourhood', 'isolated_dwelling');
    END
$$;

ALTER TABLE osm_city_point
    ALTER COLUMN place TYPE city_place USING place::city_place;
