CREATE OR REPLACE FUNCTION landuse_class(landuse TEXT, amenity TEXT, leisure TEXT, boundary TEXT) RETURNS TEXT AS $$
    SELECT CASE
         WHEN leisure = 'nature_reserve' OR boundary='national_park' THEN 'park'
         WHEN amenity IN ('school', 'university', 'kindergarten', 'college', 'library') THEN 'school'
         WHEN landuse IN('hospital', 'railway', 'cemetery', 'military', 'residential') THEN landuse
        ELSE NULL
	 END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE VIEW landuse_z4 AS (
    SELECT NULL::bigint AS osm_id, geom AS geometry, 'residential' AS landuse, NULL::text AS amenity, NULL::text AS leisure, NULL::text AS boundary, scalerank
    FROM ne_50m_urban_areas
    WHERE scalerank <= 2
);

CREATE OR REPLACE VIEW landuse_z5 AS (
    SELECT NULL::bigint AS osm_id, geom AS geometry, 'residential' AS landuse, NULL::text AS amenity, NULL::text AS leisure, NULL::text AS boundary, scalerank
    FROM ne_50m_urban_areas
);

CREATE OR REPLACE VIEW landuse_z6 AS (
    SELECT NULL::bigint AS osm_id, geom AS geometry, 'residential' AS landuse, NULL::text AS amenity, NULL::text AS leisure, NULL::text AS boundary, scalerank
    FROM ne_10m_urban_areas
);

CREATE OR REPLACE VIEW landuse_z8 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, boundary, NULL::int as scalerank FROM osm_landuse_polygon_gen5
);

CREATE OR REPLACE VIEW landuse_z9 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, boundary, NULL::int as scalerank FROM osm_landuse_polygon_gen4
);

CREATE OR REPLACE VIEW landuse_z10 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, boundary, NULL::int as scalerank FROM osm_landuse_polygon_gen3
);

CREATE OR REPLACE VIEW landuse_z11 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, boundary, NULL::int as scalerank FROM osm_landuse_polygon_gen2
);

CREATE OR REPLACE VIEW landuse_z12 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, boundary, NULL::int as scalerank FROM osm_landuse_polygon_gen1
);

CREATE OR REPLACE VIEW landuse_z13 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, boundary, NULL::int as scalerank FROM osm_landuse_polygon
    WHERE ST_Area(geometry) > 60000
);

CREATE OR REPLACE VIEW landuse_z14 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, boundary, NULL::int as scalerank FROM osm_landuse_polygon
);

CREATE OR REPLACE FUNCTION layer_landuse(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text, subclass text) AS $$
    SELECT osm_id, geometry,
        landuse_class(landuse, amenity, leisure, boundary) AS class,
        COALESCE(NULLIF(landuse, ''), NULLIF(amenity, ''), NULLIF(leisure, ''), NULLIF(boundary, '')) AS subclass
        FROM (
        SELECT * FROM landuse_z4
        WHERE zoom_level = 4
        UNION ALL
        SELECT * FROM landuse_z5
        WHERE zoom_level = 5
        UNION ALL
        SELECT * FROM landuse_z6
        WHERE zoom_level BETWEEN 6 AND 10 AND scalerank-1 <= zoom_level
        UNION ALL
        SELECT * FROM landuse_z8 WHERE zoom_level = 8
        UNION ALL
        SELECT * FROM landuse_z9 WHERE zoom_level = 9
        UNION ALL
        SELECT * FROM landuse_z10 WHERE zoom_level = 10
        UNION ALL
        SELECT * FROM landuse_z11 WHERE zoom_level = 11
        UNION ALL
        SELECT * FROM landuse_z12 WHERE zoom_level = 12
        UNION ALL
        SELECT * FROM landuse_z13 WHERE zoom_level = 13
        UNION ALL
        SELECT * FROM landuse_z14 WHERE zoom_level >= 14
    ) AS zoom_levels;
$$ LANGUAGE SQL IMMUTABLE;

