CREATE OR REPLACE VIEW rail_z13 AS (
    SELECT * FROM rail
    WHERE class='rail'
);

CREATE OR REPLACE VIEW rail_z14 AS (
    SELECT * FROM rail
);

CREATE OR REPLACE FUNCTION layer_rail(bbox geometry, zoom_level int)
RETURNS TABLE(geom geometry, class text, brunnel text) AS $$
    SELECT way AS geom, class::text, brunnel::text FROM (
        SELECT * FROM rail_z13 WHERE zoom_level = 13
        UNION ALL
        SELECT * FROM rail_z14 WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE way && bbox;
$$ LANGUAGE SQL IMMUTABLE;
