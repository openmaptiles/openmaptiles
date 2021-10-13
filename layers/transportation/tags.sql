-- Limit tags to only the ones that aren't mapped to columns
CREATE OR REPLACE FUNCTION highway_linestring_strip_tags(tags hstore) RETURNS hstore AS
$$
SELECT slice(tags,
           ARRAY[
             'bicycle',
             'foot',
             'ford',
             'horse',
             'layer',
             'mtb_scale',
             'oneway',
             'ramp',
             'toll',
             'tunnel'
           ]
       );
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;

CREATE OR REPLACE FUNCTION highway_polygon_strip_tags(tags hstore) RETURNS hstore AS
$$
SELECT slice(tags,
           ARRAY[
             'layer'
           ]
       );
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;
