CREATE OR REPLACE VIEW ice_z0 AS (
    SELECT geom, 'glacier' AS type FROM ne_110m_glaciated_areas
);

CREATE OR REPLACE VIEW ice_z2 AS (
    SELECT geom, 'glacier' AS type FROM ne_50m_glaciated_areas
    UNION ALL
    SELECT geom, 'ice_shelf' AS type FROM ne_50m_antarctic_ice_shelves_polys
);

CREATE OR REPLACE VIEW ice_z5 AS (
    SELECT geom, 'glacier' AS type FROM ne_10m_glaciated_areas
    UNION ALL
    SELECT geom, 'ice_shelf' AS type FROM ne_10m_antarctic_ice_shelves_polys
);

CREATE OR REPLACE FUNCTION layer_ice(bbox geometry, zoom_level int)
RETURNS TABLE(geom geometry, class text) AS $$
    SELECT geom, type::text AS class FROM (
        SELECT geom, type FROM ice_z0
        WHERE zoom_level BETWEEN 0 AND 1
        UNION ALL
        SELECT * FROM ice_z2
        WHERE zoom_level BETWEEN 2 AND 4
        UNION ALL
        SELECT * FROM ice_z5
        WHERE zoom_level BETWEEN 5 AND 8
    ) AS zoom_levels
    WHERE geom && bbox;
$$ LANGUAGE SQL IMMUTABLE;
