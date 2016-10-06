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
