-- Values that can be dropped from the tags hstore
CREATE FUNCTION highway_linestring_tag_discardable() RETURNS hstore AS $$
BEGIN
    RETURN hstore(ARRAY[
        ['tunnel', 'false'],
        ['ramp',   'false'],
        ['ford',   'false'],
        ['oneway', '0'],
        ['toll',   'false'],
        ['layer',   NULL]
    ]);
END;
$$ LANGUAGE plpgsql;

-- Keys that should be preserved in the tags hstore
CREATE FUNCTION highway_linestring_tag_base(tags hstore) RETURNS hstore AS $$
BEGIN
    RETURN slice(tags,
              ARRAY[
                  'bicycle',
                  'foot',
                  'ford',
                  'horse',
                  'mtb_scale'
              ]
           );
END;
$$ LANGUAGE plpgsql;


-- Clean the tags hstore to remove unneeded values
ALTER TABLE osm_highway_linestring ADD COLUMN IF NOT EXISTS transportation_tags hstore;
UPDATE osm_highway_linestring SET transportation_tags =
    (
        highway_linestring_tag_base(tags)
        -- Keys to import from imposm-generated columns
        || hstore(ARRAY[
            ['tunnel', is_tunnel::text],
            ['ramp',   is_ramp::text],
            ['ford',   is_ford::text],
            ['oneway', is_oneway::text],
            ['toll',   toll::text],
            ['layer',  layer::text]
        ])
    )
    -- Remove null/default values
    - highway_linestring_tag_discardable();
