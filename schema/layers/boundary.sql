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
