-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS osm_ocean_polygon_gen1 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_ocean_polygon -> osm_ocean_polygon_gen1
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen1 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen1 AS (
  SELECT ST_Simplify(geometry, 20) AS geometry
  FROM osm_ocean_polygon
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen1_idx ON osm_ocean_polygon_gen1 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS osm_ocean_polygon_gen2 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_ocean_polygon -> osm_ocean_polygon_gen2
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen2 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen2 AS (
  SELECT ST_Simplify(geometry, 40) AS geometry
  FROM osm_ocean_polygon
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen2_idx ON osm_ocean_polygon_gen2 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS osm_ocean_polygon_gen3 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_ocean_polygon -> osm_ocean_polygon_gen3
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen3 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen3 AS (
  SELECT ST_Simplify(geometry, 80) AS geometry
  FROM osm_ocean_polygon
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen3_idx ON osm_ocean_polygon_gen3 USING gist (geometry);


-- This statement can be deleted after the water importer image stops creating this object as a table
DO $$ BEGIN DROP TABLE IF EXISTS osm_ocean_polygon_gen4 CASCADE; EXCEPTION WHEN wrong_object_type THEN END; $$ language 'plpgsql';
-- etldoc: osm_ocean_polygon -> osm_ocean_polygon_gen4
DROP MATERIALIZED VIEW IF EXISTS osm_ocean_polygon_gen4 CASCADE;
CREATE MATERIALIZED VIEW osm_ocean_polygon_gen4 AS (
  SELECT ST_Simplify(geometry, 160) AS geometry
  FROM osm_ocean_polygon
) /* DELAY_MATERIALIZED_VIEW_CREATION */ ;
CREATE INDEX IF NOT EXISTS osm_ocean_polygon_gen4_idx ON osm_ocean_polygon_gen4 USING gist (geometry);
