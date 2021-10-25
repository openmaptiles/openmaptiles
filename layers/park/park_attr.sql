CREATE OR REPLACE FUNCTION park_attr_builder(tags hstore)
RETURNS jsonb AS $$
  SELECT jsonb_strip_nulls(
    (
      hstore_to_jsonb(tags) ||
      jsonb_build_object(
        'class',
        COALESCE(
          LOWER(REPLACE(NULLIF(tags->'protection_title', ''), ' ', '_')),
          NULLIF(tags->'boundary',''),
          NULLIF(tags->'leisure','')
        ),
        -- name_en and name_de are deprecated.  These can be deleted in OMT v4.0:
        'name_en',
        COALESCE(NULLIF(tags->'name:en', ''), tags->'name'),
        'name_de',
        COALESCE(NULLIF(tags->'name:de', ''), tags->'name', tags->'name:en')
      )
    )
    - 'protection_title'
    - 'boundary'
    - 'leisure'
    - 'type'
    - 'wikipedia'
    - 'wikidata'
  )
$$ LANGUAGE SQL;
