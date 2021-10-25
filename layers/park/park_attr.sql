CREATE TYPE park_polygon_gen_t AS (
  osm_id            bigint,
  geometry          geometry,
  name              character varying,
  name_en           character varying,
  name_de           character varying,
  tags              hstore,
  landuse           character varying,
  leisure           character varying,
  boundary          character varying,
  protection_title  character varying,
  area              real,
  geometry_point    geometry
  -- Additional fields added here by openmaptiles-tools
);

CREATE TYPE park_polygon_t AS (
  id                integer,
  osm_id            bigint,
  name              character varying,
  name_en           character varying,
  name_de           character varying,
  tags              hstore,
  landuse           character varying,
  leisure           character varying,
  boundary          character varying,
  protection_title  character varying,
  area              real,
  geometry          geometry(Geometry,3857),
  geometry_point    geometry
  -- Additional fields added here by openmaptiles-tools
);

CREATE OR REPLACE FUNCTION park_attr_builder(
                                              tags     hstore,
                                              name_en  text,
                                              name_de  text
                                            )
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
        )
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

CREATE OR REPLACE FUNCTION park_polygon_tile(rec park_polygon_gen_t)
RETURNS TABLE(osm_id bigint, geom geometry, attr jsonb) AS $$
  SELECT rec.osm_id,
         rec.geometry,
         park_attr_builder(rec.tags, rec.name_en, rec.name_de);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION park_polygon_tile(rec park_polygon_t)
RETURNS TABLE(osm_id bigint, geom geometry, attr jsonb) AS $$
  SELECT rec.osm_id,
         rec.geometry,
         park_attr_builder(rec.tags, rec.name_en, rec.name_de);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION park_point_tile(rec park_polygon_gen_t)
RETURNS TABLE(osm_id bigint, geom geometry, attr jsonb) AS $$
  SELECT rec.osm_id,
         rec.geometry_point,
         park_attr_builder(rec.tags, rec.name_en, rec.name_de);
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION park_point_tile(rec park_polygon_t)
RETURNS TABLE(osm_id bigint, geom geometry, attr jsonb) AS $$
  SELECT rec.osm_id,
         rec.geometry_point,
         park_attr_builder(rec.tags, rec.name_en, rec.name_de);
$$ LANGUAGE SQL;
