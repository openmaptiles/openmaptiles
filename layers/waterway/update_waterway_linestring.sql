DROP TRIGGER IF EXISTS trigger_refresh ON osm_waterway_linestring;

DO $$
BEGIN
  update osm_waterway_linestring SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_waterway_linestring_gen1 SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_waterway_linestring_gen2 SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
  update osm_waterway_linestring_gen3 SET tags = slice_language_tags(tags) || get_basic_names(tags, geometry);
END $$;


-- Handle updates

CREATE SCHEMA IF NOT EXISTS waterway_linestring;
CREATE OR REPLACE FUNCTION waterway_linestring.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE NOTICE 'Refresh waterway_linestring %', NEW.osm_id;
    NEW.tags = slice_language_tags(NEW.tags) || get_basic_names(NEW.tags, NEW.geometry);
    RETURN NEW;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_refresh
    BEFORE INSERT OR UPDATE ON osm_waterway_linestring
    FOR EACH ROW
    EXECUTE PROCEDURE waterway_linestring.refresh();
