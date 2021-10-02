-- Store test results

DROP TABLE IF EXISTS omt_test_failures;
CREATE TABLE omt_test_failures(
  test_id integer,
  test_type varchar(6),
  error_message text
);

-- Checks to ensure that test data was imported correctly

CREATE OR REPLACE FUNCTION test_import() RETURNS VOID AS $$

DECLARE
  cnt integer;

BEGIN

  -- Test 100
  SELECT COUNT(*) INTO cnt FROM osm_park_polygon;
  IF cnt <> 3 THEN
    INSERT INTO omt_test_failures VALUES(100, 'import', 'osm_park_polygon expected 3, got ' || cnt);
  END IF;

  SELECT COUNT(*) INTO cnt FROM osm_park_polygon_gen_z5;
  IF cnt <> 3 THEN
    INSERT INTO omt_test_failures VALUES(100, 'import', 'osm_park_polygon_gen_z5 expected 3, got ' || cnt);
  END IF;

  SELECT COUNT(*) INTO cnt FROM osm_park_polygon_gen_z5 WHERE leisure='nature_reserve';
  IF cnt <> 1 THEN
    INSERT INTO omt_test_failures VALUES(100, 'import', 'osm_park_polygon_gen_z5 nature_reserve expected 1, got ' || cnt);
  END IF;

  SELECT COUNT(*) INTO cnt FROM osm_park_polygon_gen_z5 WHERE boundary='protected_area';
  IF cnt <> 1 THEN
    INSERT INTO omt_test_failures VALUES(100, 'import', 'osm_park_polygon_gen_z5 protected_area expected 1, got ' || cnt);
  END IF;

  SELECT COUNT(*) INTO cnt FROM osm_park_polygon_gen_z5 WHERE boundary='national_park';
  IF cnt <> 1 THEN
    INSERT INTO omt_test_failures VALUES(100, 'import', 'osm_park_polygon_gen_z5 national_park expected 1, got ' || cnt);
  END IF;

  SELECT COUNT(*) INTO cnt FROM omt_test_failures;
  IF cnt > 0 THEN
    RAISE '% unit test(s) Failed.  Details can be found in table omt_test_failures.', cnt USING ERRCODE = '0Z000';
  END IF;

END;

$$
LANGUAGE plpgsql;

-- Run all tests
DO $$
BEGIN
  PERFORM test_import();
END;
$$;
