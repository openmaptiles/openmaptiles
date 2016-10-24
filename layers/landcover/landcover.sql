CREATE OR REPLACE VIEW landcover_z0 AS (
    SELECT NULL::int AS osm_id, geom AS geometry, 'glacier' AS landuse, NULL AS "natural", NULL AS wetland FROM ne_110m_glaciated_areas
);

CREATE OR REPLACE VIEW landcover_z2 AS (
    SELECT NULL::int AS osm_id, geom AS geometry, 'glacier' AS landuse, NULL AS "natural", NULL AS wetland FROM ne_50m_glaciated_areas
    UNION ALL
    SELECT NULL::int AS osm_id, geom AS geometry, 'ice_shelf' AS landuse, NULL AS "natural", NULL AS wetland FROM ne_50m_antarctic_ice_shelves_polys
);

CREATE OR REPLACE VIEW landcover_z5 AS (
    SELECT NULL::int AS osm_id, geom AS geometry, 'glacier' AS landuse, NULL AS "natural", NULL AS wetland FROM ne_10m_glaciated_areas
    UNION ALL
    SELECT NULL::int AS osm_id, geom AS geometry, 'ice_shelf' AS landuse, NULL AS "natural", NULL AS wetland FROM ne_10m_antarctic_ice_shelves_polys
);


CREATE OR REPLACE VIEW landcover_z8 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon
    WHERE ST_Area(geometry) > 15000000
);

CREATE OR REPLACE VIEW landcover_z9 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon
    WHERE ST_Area(geometry) > 4200000
);

CREATE OR REPLACE VIEW landcover_z10 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon
    WHERE ST_Area(geometry) > 1200000
);

CREATE OR REPLACE VIEW landcover_z11 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon WHERE ST_Area(geometry) > 480000
);

CREATE OR REPLACE VIEW landcover_z12 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon WHERE ST_Area(geometry) > 240000
);

CREATE OR REPLACE VIEW landcover_z13 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon WHERE ST_Area(geometry) > 60000
);

CREATE OR REPLACE VIEW landcover_z14 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon
);

CREATE OR REPLACE FUNCTION layer_landcover(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geom geometry, landuse text, "natural" text, wetland text) AS $$
    SELECT osm_id, geometry, landuse, "natural", wetland FROM (
        SELECT * FROM landcover_z0
        WHERE zoom_level BETWEEN 0 AND 1 AND geometry && bbox
        UNION ALL
        SELECT * FROM landcover_z2
        WHERE zoom_level BETWEEN 2 AND 4 AND geometry && bbox
        UNION ALL
        SELECT * FROM landcover_z5
        WHERE zoom_level BETWEEN 5 AND 7 AND geometry && bbox
        UNION ALL
        SELECT osm_id, ST_Simplify(geometry, 300) AS geometry, landuse, "natural", wetland
        FROM landcover_z8 WHERE zoom_level = 8 AND geometry && bbox
        UNION ALL
        SELECT osm_id, ST_Simplify(geometry, 200) AS geometry, landuse, "natural", wetland
        FROM landcover_z9 WHERE zoom_level = 9 AND geometry && bbox
        UNION ALL
        SELECT osm_id, ST_Simplify(geometry, 120) AS geometry, landuse, "natural", wetland
        FROM landcover_z10 WHERE zoom_level = 10 AND geometry && bbox
        UNION ALL
        SELECT osm_id, ST_Simplify(geometry, 80) AS geometry, landuse, "natural", wetland
        FROM landcover_z11 WHERE zoom_level = 11 AND geometry && bbox
        UNION ALL
        SELECT osm_id, ST_Simplify(geometry, 50) AS geometry, landuse, "natural", wetland
        FROM landcover_z12 WHERE zoom_level = 12 AND geometry && bbox
        UNION ALL
        SELECT osm_id, ST_Simplify(geometry, 10) AS geometry, landuse, "natural", wetland
        FROM landcover_z13 WHERE zoom_level = 13 AND geometry && bbox
        UNION ALL
        SELECT osm_id, geometry, landuse, "natural", wetland
        FROM landcover_z14 WHERE zoom_level >= 14 AND geometry && bbox
    ) AS zoom_levels;
$$ LANGUAGE SQL IMMUTABLE;

