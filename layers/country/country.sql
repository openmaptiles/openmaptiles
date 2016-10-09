CREATE TABLE IF NOT EXISTS country_label AS (
    SELECT topoint(geom) AS geom,
           name,
           adm0_a3, abbrev, postal,
           scalerank, labelrank,
           CASE WHEN tiny < 0 THEN 0 ELSE 1 END AS is_tiny
    FROM ne_10m_admin_0_countries
    WHERE scalerank <= 1
);
CREATE INDEX IF NOT EXISTS country_label_geom_idx ON country_label USING gist(geom);

CREATE OR REPLACE VIEW country_z0 AS (
    SELECT * FROM country_label WHERE scalerank = 0 AND is_tiny = 0 AND labelrank <= 2
);

CREATE OR REPLACE VIEW country_z1 AS (
    SELECT * FROM country_label WHERE scalerank = 0 AND is_tiny = 0 AND labelrank <= 3
);

CREATE OR REPLACE VIEW country_z2 AS (
    SELECT * FROM country_label WHERE scalerank = 0 AND is_tiny = 0 AND labelrank <= 4
);

CREATE OR REPLACE VIEW country_z3 AS (
    SELECT * FROM country_label WHERE scalerank = 0 AND is_tiny = 0
);

CREATE OR REPLACE VIEW country_z5 AS (
    SELECT * FROM country_label WHERE scalerank <= 1
);

CREATE OR REPLACE FUNCTION layer_country(bbox geometry, zoom_level int)
RETURNS TABLE(geom geometry, name text, abbrev text, postal text, scalerank int, labelrank int) AS $$
    SELECT geom, name, abbrev, postal, scalerank::int, labelrank::int FROM (
        SELECT * FROM country_z0
        WHERE zoom_level = 0
        UNION ALL
        SELECT * FROM country_z1
        WHERE zoom_level = 1
        UNION ALL
        SELECT * FROM country_z2
        WHERE zoom_level BETWEEN 2 AND 4
        UNION ALL
        SELECT * FROM country_z3
        WHERE zoom_level BETWEEN 3 AND 4
        UNION ALL
        SELECT * FROM country_z5
        WHERE zoom_level >= 5
    ) AS t
    WHERE geom && bbox
    ORDER BY scalerank ASC, labelrank ASC, length(name) ASC;
$$ LANGUAGE SQL IMMUTABLE;
