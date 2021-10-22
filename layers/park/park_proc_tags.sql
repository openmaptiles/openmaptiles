CREATE OR REPLACE FUNCTION park_tile_attr(tags jsonb) RETURNS jsonb
AS
$$
DECLARE
  attr jsonb;
  k text;
  v text;
BEGIN
  attr := tags
        - 'id'
        - 'osm_id';

  FOR k, v IN
    SELECT * FROM jsonb_each_text(tags)
  LOOP
    IF v = '' THEN
      attr := attr - k;
    END IF;
  END LOOP;

  attr :=
    (attr ||
    jsonb_build_object(
      'class',
      COALESCE(
        LOWER(REPLACE(NULLIF(attr->>'protection_title', ''), ' ', '_')),
        attr->>'boundary',
        attr->>'leisure'
      )
    )
  )
  - 'protection_title'
  - 'boundary'
  - 'leisure';

  RETURN attr;
END;
$$ LANGUAGE plpgsql IMMUTABLE
                STRICT
                PARALLEL SAFE;
