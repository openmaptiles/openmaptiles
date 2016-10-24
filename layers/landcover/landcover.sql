CREATE OR REPLACE FUNCTION landcover_class(landuse VARCHAR, "natural" VARCHAR, wetland VARCHAR) RETURNS TEXT AS $$
    SELECT CASE
         WHEN landuse IN ('farmland', 'farm', 'orchard', 'vineyard', 'plant_nursery') THEN 'farmland'
         WHEN "natural" IN ('glacier', 'ice_shelf') THEN 'ice'
         WHEN "natural"='wood' OR landuse IN ('forest', 'wood') THEN 'wood'
         WHEN "natural"='grassland' OR landuse IN ('grass', 'meadow', 'village_green', 'allotments', 'park', 'recreation_ground', 'grassland') THEN 'grass'
         WHEN "natural"='wetland' OR wetland IN ('bog', 'swamp', 'wet_meadow', 'marsh', 'reedbed', 'saltern', 'tidalflat', 'saltmarsh', 'mangrove') THEN 'wetland'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE VIEW landcover_z0 AS (
    SELECT NULL::int AS osm_id, geom AS geometry, NULL AS landuse, 'glacier' AS "natural", NULL::text AS wetland FROM ne_110m_glaciated_areas
);

CREATE OR REPLACE VIEW landcover_z2 AS (
    SELECT NULL::bigint AS osm_id, geom AS geometry, NULL::text AS landuse, 'glacier' AS "natural", NULL::text AS wetland FROM ne_50m_glaciated_areas
    UNION ALL
    SELECT NULL::bigint AS osm_id, geom AS geometry, NULL::text AS landuse, 'ice_shelf' AS "natural", NULL::text AS wetland FROM ne_50m_antarctic_ice_shelves_polys
);

CREATE OR REPLACE VIEW landcover_z5 AS (
    SELECT NULL::bigint AS osm_id, geom AS geometry, NULL::text AS landuse, 'glacier' AS "natural", NULL::text AS wetland FROM ne_10m_glaciated_areas
    UNION ALL
    SELECT NULL::bigint AS osm_id, geom AS geometry, NULL::text AS landuse, 'ice_shelf' AS "natural", NULL::text AS wetland FROM ne_10m_antarctic_ice_shelves_polys
);

CREATE OR REPLACE VIEW landcover_z8 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon_gen5
);

CREATE OR REPLACE VIEW landcover_z9 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon_gen4
);

CREATE OR REPLACE VIEW landcover_z10 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon_gen3
);

CREATE OR REPLACE VIEW landcover_z11 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon_gen2
);

CREATE OR REPLACE VIEW landcover_z12 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon_gen1
);

CREATE OR REPLACE VIEW landcover_z13 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon WHERE ST_Area(geometry) > 60000
);

CREATE OR REPLACE VIEW landcover_z14 AS (
    SELECT osm_id, geometry, landuse, "natural", wetland FROM osm_landcover_polygon
);

CREATE OR REPLACE FUNCTION layer_landcover(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text, subclass text) AS $$
    SELECT osm_id, geometry,
        landcover_class(landuse, "natural", wetland) AS class,
        COALESCE(NULLIF("natural", ''), NULLIF(landuse, ''), NULLIF('wetland', '')) AS subclass
        FROM (
        SELECT * FROM landcover_z0
        WHERE zoom_level BETWEEN 0 AND 1 AND geometry && bbox
        UNION ALL
        SELECT * FROM landcover_z2
        WHERE zoom_level BETWEEN 2 AND 4 AND geometry && bbox
        UNION ALL
        SELECT * FROM landcover_z5
        WHERE zoom_level BETWEEN 5 AND 7 AND geometry && bbox
        UNION ALL
        SELECT osm_id, geometry, landuse, "natural", wetland
        FROM landcover_z8 WHERE zoom_level = 8 AND geometry && bbox
        UNION ALL
        SELECT osm_id, geometry, landuse, "natural", wetland
        FROM landcover_z9 WHERE zoom_level = 9 AND geometry && bbox
        UNION ALL
        SELECT osm_id, geometry, landuse, "natural", wetland
        FROM landcover_z10 WHERE zoom_level = 10 AND geometry && bbox
        UNION ALL
        SELECT osm_id, geometry, landuse, "natural", wetland
        FROM landcover_z11 WHERE zoom_level = 11 AND geometry && bbox
        UNION ALL
        SELECT osm_id, geometry, landuse, "natural", wetland
        FROM landcover_z12 WHERE zoom_level = 12 AND geometry && bbox
        UNION ALL
        SELECT osm_id, ST_Simplify(geometry, 10) AS geometry, landuse, "natural", wetland
        FROM landcover_z13 WHERE zoom_level = 13 AND geometry && bbox
        UNION ALL
        SELECT osm_id, geometry, landuse, "natural", wetland
        FROM landcover_z14 WHERE zoom_level >= 14 AND geometry && bbox
    ) AS zoom_levels;
$$ LANGUAGE SQL IMMUTABLE;
