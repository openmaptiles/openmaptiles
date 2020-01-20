
-- etldoc: layer_aerodrome_label[shape=record fillcolor=lightpink, style="rounded,filled", label="layer_aerodrome_label | <z10_> z10+" ] ;

CREATE OR REPLACE FUNCTION layer_aerodrome_label(
    bbox geometry,
    zoom_level integer,
    pixel_width numeric)
  RETURNS TABLE(
    osm_id bigint,
    geometry geometry,
    name text,
    name_en text,
    name_de text,
    tags hstore,
    class text,
    iata text,
    icao text,
    ele int,
    ele_ft int) AS
$$
  -- etldoc: osm_aerodrome_label_point -> layer_aerodrome_label:z10_
  SELECT
    osm_id,
    geometry,
    name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
    tags,
    CASE
      %%FIELD_MAPPING: class %%
      ELSE 'other'
    END AS class,
    NULLIF(iata, '') AS iata,
    NULLIF(icao, '') AS icao,
    substring(ele from E'^(-?\\d+)(\\D|$)')::int AS ele,
    round(substring(ele from E'^(-?\\d+)(\\D|$)')::int*3.2808399)::int AS ele_ft
  FROM osm_aerodrome_label_point
  WHERE geometry && bbox AND zoom_level >= 10;

$$ LANGUAGE SQL IMMUTABLE;
