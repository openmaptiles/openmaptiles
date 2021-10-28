-- Store test results

DROP TABLE IF EXISTS omt_test_failures;
CREATE TABLE omt_test_failures(
  test_id integer,
  test_type varchar(6),
  error_message text
);

-- Checks to ensure that test data was imported correctly
DO $$

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

  -- Test 200
  SELECT COUNT(*) INTO cnt FROM osm_aerodrome_label_point;
  IF cnt <> 3 THEN
    INSERT INTO omt_test_failures VALUES(200, 'import', 'osm_aerodrome_label expected 3, got ' || cnt);
  END IF;

  SELECT COUNT(*) INTO cnt FROM osm_aerodrome_label_point WHERE ele=123;
  IF cnt <> 1 THEN
    INSERT INTO omt_test_failures VALUES(200, 'import', 'osm_aerodrome_label ele=123 expected 1, got ' || cnt);
  END IF;

  -- Test 300
  SELECT COUNT(*) INTO cnt FROM osm_landcover_polygon WHERE mapping_key='natural' AND subclass='wood';
  IF cnt <> 1 THEN
    INSERT INTO omt_test_failures VALUES(300, 'import', 'osm_landcover_polygon natural=wood expected 1, got ' || cnt);
  END IF;

  -- Test 400
  SELECT COUNT(DISTINCT relation_id) INTO cnt FROM osm_border_linestring WHERE admin_level=8;
  IF cnt <> 1 THEN
    INSERT INTO omt_test_failures VALUES(400, 'update', 'osm_border_linestring city count expected 1, got ' || cnt);
  END IF;

  SELECT COUNT(DISTINCT relation_id) INTO cnt FROM osm_border_linestring WHERE admin_level=2;
  IF cnt <> 1 THEN
    INSERT INTO omt_test_failures VALUES(400, 'update', 'osm_border_linestring country count expected 1, got ' || cnt);
  END IF;

END;

$$
LANGUAGE plpgsql;

DO $$

DECLARE
  cnt integer;
BEGIN
  SELECT COUNT(*) INTO cnt FROM omt_test_failures;
  IF cnt > 0 THEN
    RAISE '% unit test(s) failed on imports.  Details can be found in table omt_test_failures.', cnt USING ERRCODE = '0Z000';
  END IF;
END;

$$;
