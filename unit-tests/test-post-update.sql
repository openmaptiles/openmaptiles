-- Checks to ensure that test data was imported correctly
CREATE OR REPLACE PROCEDURE test_update()
LANGUAGE plpgsql
AS $$

DECLARE
  cnt integer;

BEGIN

  -- Test 100
  SELECT COUNT(*) INTO cnt FROM osm_park_polygon_gen_z5 WHERE boundary='national_park';
  IF cnt <> 1 THEN
    INSERT INTO omt_test_failures VALUES(100, 'update', 'osm_park_polygon_gen_z5 national_park expected 1, got ' || cnt);
  END IF;

  SELECT COUNT(*) INTO cnt FROM omt_test_failures;
  IF cnt > 0 THEN
    RAISE '% unit test(s) failed on updates.  Details can be found in table omt_test_failures.', cnt USING ERRCODE = '0Z000';
  END IF;

END;

$$;

DO $$
BEGIN
-- Run all tests
  PERFORM test_update();
END;
$$;
