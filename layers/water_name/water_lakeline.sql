
-- etldoc:  osm_water_polygon ->  osm_water_lakeline
-- etldoc:  lake_centerline  ->  osm_water_lakeline
CREATE MATERIALIZED VIEW osm_water_lakeline AS (
	SELECT wp.osm_id,
		ll.wkb_geometry AS geometry,
		name, name_en, ST_Area(wp.geometry) AS area
    FROM osm_water_polygon AS wp
    INNER JOIN lake_centerline ll ON wp.osm_id = ll.osm_id
    WHERE wp.name <> ''
);
CREATE INDEX IF NOT EXISTS osm_water_lakeline_geometry_idx ON osm_water_lakeline USING gist(geometry);

-- Triggers

CREATE OR REPLACE FUNCTION refresh_osm_water_lakeline() RETURNS trigger AS
  $BODY$
  BEGIN
    REFRESH MATERIALIZED VIEW osm_water_lakeline;
      RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_refresh_osm_water_lakeline
    AFTER INSERT OR UPDATE OR DELETE ON osm_water_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE refresh_osm_water_lakeline();
