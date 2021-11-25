CREATE OR REPLACE FUNCTION transportation_name_tags(geometry geometry, tags hstore, name text, name_en text, name_de text) RETURNS hstore AS
$$
SELECT hstore(string_agg(nullif(slice_language_tags(tags ||
                     hstore(ARRAY [
                       'name',    CASE WHEN length(name) > 15    THEN osml10n_street_abbrev_all(name)   ELSE NULLIF(name, '') END,
                       'name:en', CASE WHEN length(name_en) > 15 THEN osml10n_street_abbrev_en(name_en) ELSE NULLIF(name_en, '') END,
                       'name:de', CASE WHEN length(name_de) > 15 THEN osml10n_street_abbrev_de(name_de) ELSE NULLIF(name_de, '') END
                     ]))::text,
                     ''), ','))
                     || get_basic_names(tags, geometry);
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;


