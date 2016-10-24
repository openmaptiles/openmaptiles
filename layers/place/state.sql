CREATE OR REPLACE FUNCTION fix_win1252_shp_encoding(str TEXT) RETURNS TEXT
AS $$
BEGIN
    RETURN convert_from(convert_to(str, 'WIN1252'), 'UTF-8');
    EXCEPTION WHEN others THEN RETURN str;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE TABLE IF NOT EXISTS state_label AS (
    SELECT topoint(geom) AS geometry,
           NULL::bigint AS osm_id,
           name_local, fix_win1252_shp_encoding(name) AS name_en,
           abbrev, postal,
           scalerank, labelrank,
           shape_area, datarank, type
    FROM ne_10m_admin_1_states_provinces_shp
    WHERE type IN ('State', 'Avtonomnyy Okrug', 'Sheng', 'Estado')
    AND scalerank <= 3 AND labelrank <= 2
);
CREATE INDEX IF NOT EXISTS state_label_geometry_idx ON state_label USING gist(geometry);

CREATE OR REPLACE VIEW state_z3 AS (
    SELECT * FROM state_label
    WHERE (scalerank <= 2 AND labelrank <= 1) OR type = 'Avtonomnyy Okrug'
);

CREATE OR REPLACE VIEW state_z4 AS (
    SELECT * FROM state_label
);

CREATE OR REPLACE FUNCTION layer_state(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, abbrev text, postal text, scalerank int, labelrank int) AS $$
    SELECT osm_id, geometry,
    COALESCE(name_local, name_en) AS name_local, name_en,
    abbrev, postal, scalerank::int, labelrank::int FROM (
        SELECT * FROM state_z3
        WHERE zoom_level = 3
        UNION ALL
        SELECT * FROM state_z4
        WHERE zoom_level >= 4
    ) AS t
    WHERE geometry && bbox
    ORDER BY scalerank ASC, labelrank ASC, shape_area DESC;
$$ LANGUAGE SQL IMMUTABLE;
