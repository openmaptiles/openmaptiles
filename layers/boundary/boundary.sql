

-- etldoc: ne_110m_admin_0_boundary_lines_land  -> boundary_z0

CREATE OR REPLACE VIEW boundary_z0 AS (
    SELECT geometry, 2 AS admin_level, false AS disputed, false AS maritime
    FROM ne_110m_admin_0_boundary_lines_land
);

-- etldoc: ne_50m_admin_0_boundary_lines_land  -> boundary_z1
-- etldoc: ne_50m_admin_1_states_provinces_lines -> boundary_z1

CREATE OR REPLACE VIEW boundary_z1 AS (
    SELECT geometry, 2 AS admin_level, false AS disputed, false AS maritime
    FROM ne_50m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geometry, 4 AS admin_level, false AS disputed, false AS maritime
    FROM ne_50m_admin_1_states_provinces_lines
);


-- etldoc: ne_50m_admin_0_boundary_lines_land -> boundary_z3
-- etldoc: ne_50m_admin_1_states_provinces_lines -> boundary_z3

CREATE OR REPLACE VIEW boundary_z3 AS (
    SELECT geometry, 2 AS admin_level, false AS disputed, false AS maritime
    FROM ne_50m_admin_0_boundary_lines_land
    UNION ALL
    SELECT geometry, 4 AS admin_level, false AS disputed, false AS maritime
    FROM ne_50m_admin_1_states_provinces_lines
);


-- etldoc: ne_10m_admin_0_boundary_lines_land -> boundary_z4
-- etldoc: ne_10m_admin_1_states_provinces_lines -> boundary_z4
-- etldoc: osm_border_linestring_gen10 -> boundary_z4

CREATE OR REPLACE VIEW boundary_z4 AS (
    SELECT geometry, 2 AS admin_level, false AS disputed, false AS maritime
    FROM ne_10m_admin_0_boundary_lines_land
    WHERE featurecla <> 'Lease limit'
    UNION ALL
    SELECT geometry, 4 AS admin_level, false AS disputed, false AS maritime
    FROM ne_10m_admin_1_states_provinces_lines
    WHERE min_zoom <= 5
    UNION ALL
    SELECT geometry, admin_level, disputed, maritime
    FROM osm_border_linestring_gen10
    WHERE maritime=true AND admin_level <= 2
);

-- etldoc: osm_border_linestring_gen9 -> boundary_z5

CREATE OR REPLACE VIEW boundary_z5 AS (
    SELECT geometry, admin_level, disputed, maritime
    FROM osm_border_linestring_gen9
    WHERE admin_level <= 4
);

-- etldoc: osm_border_linestring_gen8 -> boundary_z6
CREATE OR REPLACE VIEW boundary_z6 AS (
    SELECT geometry, admin_level, disputed, maritime
    FROM osm_border_linestring_gen8
    WHERE admin_level <= 4
);

-- etldoc: osm_border_linestring_gen7 -> boundary_z7
CREATE OR REPLACE VIEW boundary_z7 AS (
    SELECT geometry, admin_level, disputed, maritime
    FROM osm_border_linestring_gen7
    WHERE admin_level <= 4
);

-- etldoc: osm_border_linestring_gen6 -> boundary_z8
CREATE OR REPLACE VIEW boundary_z8 AS (
    SELECT geometry, admin_level, disputed, maritime
    FROM osm_border_linestring_gen6
    WHERE admin_level <= 4
);

-- etldoc: osm_border_linestring_gen5 -> boundary_z9
CREATE OR REPLACE VIEW boundary_z9 AS (
    SELECT geometry, admin_level, disputed, maritime
    FROM osm_border_linestring_gen5
    WHERE admin_level <= 6
);

-- etldoc: osm_border_linestring_gen4 -> boundary_z10
CREATE OR REPLACE VIEW boundary_z10 AS (
    SELECT geometry, admin_level, disputed, maritime
    FROM osm_border_linestring_gen4
    WHERE admin_level <= 6
);

-- etldoc: osm_border_linestring_gen3 -> boundary_z11
CREATE OR REPLACE VIEW boundary_z11 AS (
    SELECT geometry, admin_level, disputed, maritime
    FROM osm_border_linestring_gen3
    WHERE admin_level <= 8
);

-- etldoc: osm_border_linestring_gen2 -> boundary_z12
CREATE OR REPLACE VIEW boundary_z12 AS (
    SELECT geometry, admin_level, disputed, maritime
    FROM osm_border_linestring_gen2
);

-- etldoc: osm_border_linestring_gen1 -> boundary_z13
CREATE OR REPLACE VIEW boundary_z13 AS (
    SELECT geometry, admin_level, disputed, maritime
    FROM osm_border_linestring_gen1
);

-- etldoc: layer_boundary[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_boundary |<z0> z0 |<z1_2> z1_2 | <z3> z3 | <z4> z4 | <z5> z5 | <z6> z6 | <z7> z7 | <z8> z8 | <z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13+"]

CREATE OR REPLACE FUNCTION layer_boundary (bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, admin_level int, disputed int, maritime int) AS $$
    SELECT geometry, admin_level, disputed::int, maritime::int FROM (
        -- etldoc: boundary_z0 ->  layer_boundary:z0
        SELECT * FROM boundary_z0 WHERE geometry && bbox AND zoom_level = 0
        UNION ALL
        -- etldoc: boundary_z1 ->  layer_boundary:z1_2
        SELECT * FROM boundary_z1 WHERE geometry && bbox AND zoom_level BETWEEN 1 AND 2
        UNION ALL
        -- etldoc: boundary_z3 ->  layer_boundary:z3
        SELECT * FROM boundary_z3 WHERE geometry && bbox AND zoom_level = 3
        UNION ALL
        -- etldoc: boundary_z4 ->  layer_boundary:z4
        SELECT * FROM boundary_z4 WHERE geometry && bbox AND zoom_level = 4
        UNION ALL
        -- etldoc: boundary_z5 ->  layer_boundary:z5
        SELECT * FROM boundary_z5 WHERE geometry && bbox AND zoom_level = 5
        UNION ALL
        -- etldoc: boundary_z6 ->  layer_boundary:z6
        SELECT * FROM boundary_z6 WHERE geometry && bbox AND zoom_level = 6
        UNION ALL
        -- etldoc: boundary_z7 ->  layer_boundary:z7
        SELECT * FROM boundary_z7 WHERE geometry && bbox AND zoom_level = 7
        UNION ALL
        -- etldoc: boundary_z8 ->  layer_boundary:z8
        SELECT * FROM boundary_z8 WHERE geometry && bbox AND zoom_level = 8
        UNION ALL
        -- etldoc: boundary_z9 ->  layer_boundary:z9
        SELECT * FROM boundary_z9 WHERE geometry && bbox AND zoom_level = 9
        UNION ALL
        -- etldoc: boundary_z10 ->  layer_boundary:z10
        SELECT * FROM boundary_z10 WHERE geometry && bbox AND zoom_level = 10
        UNION ALL
        -- etldoc: boundary_z11 ->  layer_boundary:z11
        SELECT * FROM boundary_z11 WHERE geometry && bbox AND zoom_level = 11
        UNION ALL
        -- etldoc: boundary_z12 ->  layer_boundary:z12
        SELECT * FROM boundary_z12 WHERE geometry && bbox AND zoom_level = 12
        UNION ALL
        -- etldoc: boundary_z13 -> layer_boundary:z13
        SELECT * FROM boundary_z13 WHERE geometry && bbox AND zoom_level >= 13
    ) AS zoom_levels;
$$ LANGUAGE SQL IMMUTABLE;
