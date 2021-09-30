-- Checks to ensure that test data was imported correctly

CREATE OR REPLACE FUNCTION test_update() RETURNS VOID AS $$

DECLARE
  cnt integer;

BEGIN
  RAISE 'fail' USING ERRCODE='0Z000';

  -- Test 100

--  SELECT COUNT(*) INTO cnt FROM osm_park_polygon_gen_z5 WHERE boundary='national_park';
--  IF cnt <> 1 THEN
--    RAISE 'Test 100 Failed: osm_park_polygon_gen_z5 national_park expected 1, got %', cnt USING ERRCODE = '0Z000';
--  END IF;

END;

$$
LANGUAGE plpgsql;

-- Run all tests
DO $$
BEGIN
  PERFORM test_update();
END;
$$;
