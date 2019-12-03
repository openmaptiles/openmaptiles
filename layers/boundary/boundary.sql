CREATE OR REPLACE FUNCTION osm_disp_view(osm_id bigint) RETURNS TEXT AS $$
    SELECT CASE
        WHEN osm_id IN (
            45673585, 45673657, 45674360, 150360411, 150386750, 150388525, 150388674, 150388712, 150388910, 150453690, 157662322, 685735798, 686172489, 686271190, 725338981, 725454503, 725454510, 726173143, 726173146, 726194612, 726194617, 726194626, 726194627, 726621531, 726621535, 727083470, 727083477, 727097384, 727134387, 727134393, 727134409, 727134437, 727134440, 727134443, 727134446, 727256095, 727256098, 727256101, 727273115, 727273122, 727305082, 727305088
        ) THEN 'arunachalpradesh_cn'
        WHEN osm_id IN (
            28293977, 150454541, 150454542, 150455336, 150455337, 150466660, 150467988, 203591110, 203748568, 203748569, 203748570, 204419561, 289333530, 304171537, 304171921, 533608851, 537394875, 537395722, 537398859, 685682316, 685691854, 689501181, 727077458, 727077477, 727124728, 727124731, 727241929, 727241932, 727251539, 727297492, 727297495, 727301621, 727301633, 727301676, 727312649, 727312652
        ) THEN 'arunachalpradesh_in'
        WHEN osm_id IN (
            30555413, 130072435, 130072449, 130072455, 130072456, 130207714, 130207721, 130207737, 171255708, 216249910, 216249912, 310894006, 310894007, 320568448, 330695989, 330695990, 330696000, 330696028, 330696042
        ) THEN 'crimea_ru'
        WHEN osm_id IN (
            238797482
        ) THEN 'crimea_ua'
	WHEN osm_id IN (
            201863238, 201863239, 201863240, 201864290, 201864292, 201864293, 201864294, 201864295, 201864296, 201963200, 201963201, 201963202, 201963203, 201963204, 201963205, 201989202, 201989204, 201989208, 201989209, 201989226, 201989228, 201989247, 202058477, 202058478, 202070077, 202070079, 202070080, 204426588, 204784124, 229236326, 296627548, 296644252, 340317212, 537069331, 680010955
        ) THEN 'kashmir_cn'
	WHEN osm_id IN (
            201864281, 201864282, 201864283, 201864284, 201864285, 201864286, 201864287, 201864288, 201864289, 201864299, 201963216, 201963227, 201989201, 201989211, 201989213, 201989222, 201989224, 202057037, 202057038, 202057039, 202057040, 202057041, 202057042, 204433493, 204779876, 204779877, 296644258, 296653822, 296653823, 296654260, 296654261, 320783762, 340291900, 47377950, 47378180, 484548263, 484823878, 537050618, 537050619, 537052157, 680010957, 686176608
        ) THEN 'kashmir_in'
	WHEN osm_id IN (
            201799448, 201864291, 201864297, 201989205, 201989207, 201989210, 201989218, 201989219, 201989225, 201989227, 202062117, 204779878, 340317211, 525054377, 536962318, 536962322, 537053851, 563799816
        ) THEN 'kashmir_cn_in'
        WHEN osm_id IN (
            90129517, 90636907, 90637115, 90637214, 90637485, 90638288, 90638356, 118190136, 118190137, 149490479, 158074534, 158079190, 158081815, 206000582, 216476286, 216476296, 338757997, 339053055, 390884608, 393887981, 394177404, 394180736, 405390305, 428466390, 428466392, 448291169, 448295000, 448297115, 448298750, 448300864, 448305706, 448305828, 448306389, 448306618, 448307293, 448455305, 448456822, 448469163, 448485363, 448485364, 448485566, 448486302, 448491191, 448491607, 448632555, 448639102, 448660355, 451604206, 451731909, 451731919, 451741668, 467969177, 472039913, 472039914, 472040165, 472040624, 472040954, 472048827, 472292969, 472304203, 472304841, 472305634, 472490881, 472494277, 472494278, 472529466, 472531380, 472550812, 472550814, 490355906, 490355908, 490358736, 490358737, 490360543, 490450902, 490451026, 490451255, 490456483, 490456484, 490503890, 490504150, 490505419, 490506839, 490509125, 490510600, 514309457, 515488623, 515491311, 515493007, 515494040, 515494041, 516608310, 516609987, 516609988, 516609989, 516612015, 516612891, 516616369, 516617618, 516624322, 535290526, 535333593, 546678720, 562960210, 562961378, 562999330, 562999929, 563000189, 563000492, 563000951, 563009278, 563009279, 563011686, 563012366, 683976449, 683976450, 684641305, 684641306
        ) THEN 'kosovo_xk'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION ne10_disp_view(ogc_fid int) RETURNS TEXT AS $$
    SELECT CASE
	WHEN ogc_fid IN (34) THEN 'arunachalpradesh_in'
        WHEN ogc_fid IN (462) THEN 'crimea_ru'
	WHEN ogc_fid IN (25, 141, 443, 444) THEN 'kashmir_cn'
	WHEN ogc_fid IN (343, 413, 414) THEN 'kashmir_in'
	WHEN ogc_fid IN (411, 412, 434) THEN 'kashmir_cn_in'
	WHEN ogc_fid IN (435) THEN 'kashmir_pk'
	WHEN ogc_fid IN (188) THEN 'kosovo_xk'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION ne50_disp_view(ogc_fid int) RETURNS TEXT AS $$
    SELECT CASE
	WHEN ogc_fid IN (10) THEN 'arunachalpradesh_in'
        WHEN ogc_fid IN (361) THEN 'crimea_ru'
	WHEN ogc_fid IN (8, 93) THEN 'kashmir_cn'
	WHEN ogc_fid IN (127) THEN 'kosovo_xk'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;


CREATE OR REPLACE FUNCTION ne110_disp_view(ogc_fid int) RETURNS TEXT AS $$
    SELECT CASE
	WHEN ogc_fid IN (178) THEN 'arunachalpradesh_in'
        WHEN ogc_fid IN (186) THEN 'crimea_ru'
	WHEN ogc_fid IN (175, 177) THEN 'kashmir_cn'
	WHEN ogc_fid IN (156) THEN 'kosovo_xk'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;




-- etldoc: ne_110m_admin_0_boundary_lines_land  -> boundary_z0

CREATE OR REPLACE VIEW boundary_z0 AS (
    SELECT 0 AS osm_id, geometry,
        2 AS admin_level,
        (CASE WHEN featurecla LIKE 'Disputed%' THEN true ELSE false END) AS disputed,
        ne110_disp_view(ogc_fid) AS disputed_view,
        false AS maritime
    FROM ne_110m_admin_0_boundary_lines_land
);

-- etldoc: ne_50m_admin_0_boundary_lines_land  -> boundary_z1
-- etldoc: ne_50m_admin_1_states_provinces_lines -> boundary_z1

CREATE OR REPLACE VIEW boundary_z1 AS (
    SELECT 0 AS osm_id, geometry,
        2 AS admin_level,
        (CASE WHEN featurecla LIKE 'Disputed%' THEN true ELSE false END) AS disputed,
        ne50_disp_view(ogc_fid) AS disputed_view,
        false AS maritime
    FROM ne_50m_admin_0_boundary_lines_land
    UNION ALL
    SELECT 0 AS osm_id, geometry,
        4 AS admin_level,
        false AS disputed,
        NULL AS disputed_view,
        false AS maritime
    FROM ne_50m_admin_1_states_provinces_lines
);


-- etldoc: ne_50m_admin_0_boundary_lines_land -> boundary_z3
-- etldoc: ne_50m_admin_1_states_provinces_lines -> boundary_z3

CREATE OR REPLACE VIEW boundary_z3 AS (
    SELECT 0 AS osm_id, geometry,
        2 AS admin_level,
        (CASE WHEN featurecla LIKE 'Disputed%' THEN true ELSE false END) AS disputed,
        ne50_disp_view(ogc_fid) AS disputed_view,
        false AS maritime
    FROM ne_50m_admin_0_boundary_lines_land
    UNION ALL
    SELECT 0 AS osm_id, geometry,
        4 AS admin_level,
        false AS disputed,
        NULL AS disputed_view,
        false AS maritime
    FROM ne_50m_admin_1_states_provinces_lines
);


-- etldoc: ne_10m_admin_0_boundary_lines_land -> boundary_z4
-- etldoc: ne_10m_admin_1_states_provinces_lines -> boundary_z4
-- etldoc: osm_border_linestring_gen10 -> boundary_z4

CREATE OR REPLACE VIEW boundary_z4 AS (
    SELECT 0 AS osm_id, geometry,
        2 AS admin_level,
        (CASE WHEN featurecla LIKE 'Disputed%' THEN true ELSE false END) AS disputed,
        ne10_disp_view(ogc_fid) AS disputed_view,
        false AS maritime
    FROM ne_10m_admin_0_boundary_lines_land
    WHERE featurecla <> 'Lease limit'
    UNION ALL
    SELECT 0 AS osm_id, geometry,
        4 AS admin_level,
        false AS disputed,
        NULL AS disputed_view,
        false AS maritime
    FROM ne_10m_admin_1_states_provinces_lines
    WHERE min_zoom <= 5
    UNION ALL
    SELECT osm_id, geometry, admin_level, disputed, osm_disp_view(osm_id) AS disputed_view, maritime
    FROM osm_border_linestring_gen10
    WHERE maritime=true AND admin_level <= 2
);

-- etldoc: osm_border_linestring_gen9 -> boundary_z5

CREATE OR REPLACE VIEW boundary_z5 AS (
    SELECT osm_id, geometry, admin_level, disputed, osm_disp_view(osm_id) AS disputed_view, maritime
    FROM osm_border_linestring_gen9
    WHERE admin_level <= 4
);

-- etldoc: osm_border_linestring_gen8 -> boundary_z6
CREATE OR REPLACE VIEW boundary_z6 AS (
    SELECT osm_id, geometry, admin_level, disputed, osm_disp_view(osm_id) AS disputed_view, maritime
    FROM osm_border_linestring_gen8
    WHERE admin_level <= 4
);

-- etldoc: osm_border_linestring_gen7 -> boundary_z7
CREATE OR REPLACE VIEW boundary_z7 AS (
    SELECT osm_id, geometry, admin_level, disputed, osm_disp_view(osm_id) AS disputed_view, maritime
    FROM osm_border_linestring_gen7
    WHERE admin_level <= 4
);

-- etldoc: osm_border_linestring_gen6 -> boundary_z8
CREATE OR REPLACE VIEW boundary_z8 AS (
    SELECT osm_id, geometry, admin_level, disputed, osm_disp_view(osm_id) AS disputed_view, maritime
    FROM osm_border_linestring_gen6
    WHERE admin_level <= 4
);

-- etldoc: osm_border_linestring_gen5 -> boundary_z9
CREATE OR REPLACE VIEW boundary_z9 AS (
    SELECT osm_id, geometry, admin_level, disputed, osm_disp_view(osm_id) AS disputed_view, maritime
    FROM osm_border_linestring_gen5
    WHERE admin_level <= 6
);

-- etldoc: osm_border_linestring_gen4 -> boundary_z10
CREATE OR REPLACE VIEW boundary_z10 AS (
    SELECT osm_id, geometry, admin_level, disputed, osm_disp_view(osm_id) AS disputed_view, maritime
    FROM osm_border_linestring_gen4
    WHERE admin_level <= 6
);

-- etldoc: osm_border_linestring_gen3 -> boundary_z11
CREATE OR REPLACE VIEW boundary_z11 AS (
    SELECT osm_id, geometry, admin_level, disputed, osm_disp_view(osm_id) AS disputed_view, maritime
    FROM osm_border_linestring_gen3
    WHERE admin_level <= 8
);

-- etldoc: osm_border_linestring_gen2 -> boundary_z12
CREATE OR REPLACE VIEW boundary_z12 AS (
    SELECT osm_id, geometry, admin_level, disputed, osm_disp_view(osm_id) AS disputed_view, maritime
    FROM osm_border_linestring_gen2
);

-- etldoc: osm_border_linestring_gen1 -> boundary_z13
CREATE OR REPLACE VIEW boundary_z13 AS (
    SELECT osm_id, geometry, admin_level, disputed, osm_disp_view(osm_id) AS disputed_view, maritime
    FROM osm_border_linestring_gen1
);

-- etldoc: layer_boundary[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="<sql> layer_boundary |<z0> z0 |<z1_2> z1_2 | <z3> z3 | <z4> z4 | <z5> z5 | <z6> z6 | <z7> z7 | <z8> z8 | <z9> z9 |<z10> z10 |<z11> z11 |<z12> z12|<z13> z13+"]

CREATE OR REPLACE FUNCTION layer_boundary (bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, admin_level int, disputed int, disputed_view text, maritime int) AS $$
    SELECT geometry, admin_level, disputed::int, disputed_view, maritime::int FROM (
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
