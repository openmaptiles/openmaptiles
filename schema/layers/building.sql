CREATE OR REPLACE VIEW building_z13 AS (
    SELECT osm_id, way, height, levels FROM buildings WHERE way_area > 1400
);

CREATE OR REPLACE VIEW building_z14 AS (
    SELECT osm_id, way, height, levels FROM buildings
);
