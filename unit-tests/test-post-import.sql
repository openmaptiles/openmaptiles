-- Checks to ensure that test data was imported correctly

CREATE OR REPLACE FUNCTION test_import() RETURNS VOID AS $$

DECLARE
  cnt integer;

BEGIN

  -- Test 100
  SELECT COUNT(*) INTO cnt FROM osm_park_polygon;
  IF cnt <> 3 THEN
    RAISE 'Test 100 Failed: osm_park_polygon expected 3, got %', cnt USING ERRCODE = '0Z000';
  END IF;

  SELECT COUNT(*) INTO cnt FROM osm_park_polygon_gen_z5;
  IF cnt <> 3 THEN
    RAISE 'Test 100 Failed: osm_park_polygon_gen_z5 expected 3, got %', cnt USING ERRCODE = '0Z000';
  END IF;

  SELECT COUNT(*) INTO cnt FROM osm_park_polygon_gen_z5 WHERE leisure='nature_reserve';
  IF cnt <> 1 THEN
    RAISE 'Test 100 Failed: osm_park_polygon_gen_z5 nature_reserve expected 1, got %', cnt USING ERRCODE = '0Z000';
  END IF;

  SELECT COUNT(*) INTO cnt FROM osm_park_polygon_gen_z5 WHERE boundary='protected_area';
  IF cnt <> 1 THEN
    RAISE 'Test 100 Failed: osm_park_polygon_gen_z5 protected_area expected 1, got %', cnt USING ERRCODE = '0Z000';
  END IF;

  SELECT COUNT(*) INTO cnt FROM osm_park_polygon_gen_z5 WHERE boundary='national_park';
  IF cnt <> 1 THEN
    RAISE 'Test 100 Failed: osm_park_polygon_gen_z5 national_park expected 1, got %', cnt USING ERRCODE = '0Z000';
  END IF;

END;

$$
LANGUAGE plpgsql;

-- Run all tests
SELECT test_import();
