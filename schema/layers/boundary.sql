CREATE OR REPLACE FUNCTION boundary_class(featureclass VARCHAR) RETURNS VARCHAR
AS $$
BEGIN
    RETURN CASE
        WHEN featureclass ILIKE 'line of control%' THEN 'control'
        WHEN featureclass ILIKE 'disputed%' THEN 'dispute'
        WHEN featureclass ILIKE 'lease%' THEN 'lease'
        WHEN featureclass ILIKE 'overlay%' THEN 'overlay'
        ELSE 'boundary'
    END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

CREATE OR REPLACE VIEW boundary_z0 AS (
    SELECT geom, 0 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_110m_admin_0_boundary_lines_land
);

CREATE OR REPLACE VIEW boundary_z1 AS (
    SELECT geom, 0 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_50m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geom, 1 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_50m_admin_1_states_provinces_lines
    WHERE scalerank <= 2
);

CREATE OR REPLACE VIEW boundary_z3 AS (
    SELECT geom, 0 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_50m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geom, 1 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_50m_admin_1_states_provinces_lines
);

CREATE OR REPLACE VIEW boundary_z4 AS (
    SELECT geom, 0 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_10m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geom, 1 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_10m_admin_1_states_provinces_lines_shp
    WHERE scalerank <= 3 AND featurecla = 'Adm-1 boundary'
);

CREATE OR REPLACE VIEW boundary_z5 AS (
    SELECT geom, 0 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_10m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geom, 1 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_10m_admin_1_states_provinces_lines_shp
    WHERE scalerank <= 7 AND featurecla = 'Adm-1 boundary'
);

CREATE OR REPLACE VIEW boundary_z7 AS (
    SELECT geom, 0 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_10m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geom, 1 AS admin_level, scalerank,
           boundary_class(featurecla) AS class
    FROM ne_10m_admin_1_states_provinces_lines_shp
    WHERE featurecla = 'Adm-1 boundary'

);

CREATE OR REPLACE VIEW boundary_z8 AS (
    SELECT way AS geom, level AS admin_level,
           NULL AS scalerank, NULL AS class
    FROM admin_line
    WHERE level <= 4
);

CREATE OR REPLACE VIEW boundary_z10 AS (
    SELECT way AS geom, level AS admin_level,
           NULL AS scalerank, NULL AS class
    FROM admin_line
    WHERE level <= 8
);

CREATE OR REPLACE FUNCTION layer_boundary (bbox geometry, zoom_level int)
RETURNS TABLE(geom geometry, admin_level int, scalerank int, class text) AS $$
    SELECT geom, admin_level, scalerank::int, class FROM (
        SELECT * FROM boundary_z0 WHERE zoom_level = 0
        UNION ALL
        SELECT * FROM boundary_z1 WHERE zoom_level BETWEEN 1 AND 2
        UNION ALL
        SELECT * FROM boundary_z3 WHERE zoom_level = 3
        UNION ALL
        SELECT * FROM boundary_z4 WHERE zoom_level = 4
        UNION ALL
        SELECT * FROM boundary_z5 WHERE zoom_level BETWEEN 5 AND 6
        UNION ALL
        SELECT * FROM boundary_z7 WHERE zoom_level = 7
        UNION ALL
        SELECT ST_Simplify(geom, 400) AS geom, admin_level, scalerank, class
        FROM boundary_z8 WHERE zoom_level = 8
        UNION ALL
        SELECT ST_Simplify(geom, 320) AS geom, admin_level, scalerank, class
        FROM boundary_z8 WHERE zoom_level = 9
        UNION ALL
        SELECT ST_Simplify(geom, 150) AS geom, admin_level, scalerank, class
        FROM boundary_z10 WHERE zoom_level = 10
        UNION ALL
        SELECT ST_Simplify(geom, 100) AS geom, admin_level, scalerank, class
        FROM boundary_z10 WHERE zoom_level = 11
        UNION ALL
        SELECT ST_Simplify(geom, 50) AS geom, admin_level, scalerank, class
        FROM boundary_z10 WHERE zoom_level = 12
        UNION ALL
        SELECT geom, admin_level, scalerank, class
        FROM boundary_z10 WHERE zoom_level >= 13
    ) AS zoom_levels
    WHERE geom && bbox;
$$ LANGUAGE SQL IMMUTABLE;
