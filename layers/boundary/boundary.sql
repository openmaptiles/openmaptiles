CREATE OR REPLACE VIEW boundary_z0 AS (
    SELECT geom, 2 AS admin_level
    FROM ne_110m_admin_0_boundary_lines_land
);

CREATE OR REPLACE VIEW boundary_z1 AS (
    SELECT geom, 2 AS admin_level
    FROM ne_50m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geom, 4 AS admin_level
    FROM ne_50m_admin_1_states_provinces_lines
    WHERE scalerank <= 2
);

CREATE OR REPLACE VIEW boundary_z3 AS (
    SELECT geom, 2 AS admin_level
    FROM ne_50m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geom, 4 AS admin_level
    FROM ne_50m_admin_1_states_provinces_lines
);

CREATE OR REPLACE VIEW boundary_z4 AS (
    SELECT geom, 2 AS admin_level
    FROM ne_10m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geom, 4 AS admin_level
    FROM ne_10m_admin_1_states_provinces_lines_shp
    WHERE scalerank <= 3 AND featurecla = 'Adm-1 boundary'
);

CREATE OR REPLACE VIEW boundary_z5 AS (
    SELECT geom, 2 AS admin_level
    FROM ne_10m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geom, 4 AS admin_level
    FROM ne_10m_admin_1_states_provinces_lines_shp
    WHERE scalerank <= 7 AND featurecla = 'Adm-1 boundary'
);

CREATE OR REPLACE VIEW boundary_z7 AS (
    SELECT geom, 2 AS admin_level
    FROM ne_10m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geom, 4 AS admin_level
    FROM ne_10m_admin_1_states_provinces_lines_shp
    WHERE featurecla = 'Adm-1 boundary'

);

CREATE OR REPLACE VIEW boundary_z8 AS (
    SELECT geometry AS geom, admin_level
    FROM osm_boundary_linestring_gen5
    WHERE admin_level <= 4 AND ST_Length(geometry) > 1000
);

CREATE OR REPLACE VIEW boundary_z9 AS (
    SELECT geometry AS geom, admin_level
    FROM osm_boundary_linestring_gen4
    WHERE admin_level <= 6
);

CREATE OR REPLACE VIEW boundary_z10 AS (
    SELECT geometry AS geom, admin_level
    FROM osm_boundary_linestring_gen3
    WHERE admin_level <= 6
);

CREATE OR REPLACE VIEW boundary_z11 AS (
    SELECT geometry AS geom, admin_level
    FROM osm_boundary_linestring_gen2
    WHERE admin_level <= 8
);

CREATE OR REPLACE VIEW boundary_z12 AS (
    SELECT geometry AS geom, admin_level
    FROM osm_boundary_linestring_gen1
);

CREATE OR REPLACE FUNCTION layer_boundary (bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, admin_level int) AS $$
    SELECT geom, admin_level FROM (
        SELECT * FROM boundary_z0 WHERE geom && bbox AND zoom_level = 0
        UNION ALL
        SELECT * FROM boundary_z1 WHERE geom && bbox AND zoom_level BETWEEN 1 AND 2
        UNION ALL
        SELECT * FROM boundary_z3 WHERE geom && bbox AND zoom_level = 3
        UNION ALL
        SELECT * FROM boundary_z4 WHERE geom && bbox AND zoom_level = 4
        UNION ALL
        SELECT * FROM boundary_z5 WHERE geom && bbox AND zoom_level BETWEEN 5 AND 6
        UNION ALL
        SELECT * FROM boundary_z7 WHERE geom && bbox AND zoom_level = 7
        UNION ALL
        SELECT * FROM boundary_z8 WHERE geom && bbox AND zoom_level = 8
        UNION ALL
        SELECT * FROM boundary_z9 WHERE geom && bbox AND zoom_level = 9
        UNION ALL
        SELECT * FROM boundary_z10 WHERE geom && bbox AND zoom_level = 10
        UNION ALL
        SELECT * FROM boundary_z11 WHERE geom && bbox AND zoom_level = 11
        UNION ALL
        SELECT * FROM boundary_z12 WHERE geom && bbox AND zoom_level = 12
        UNION ALL
        SELECT * FROM boundary_z12 WHERE geom && bbox AND zoom_level >= 13
    ) AS zoom_levels;
$$ LANGUAGE SQL IMMUTABLE;
