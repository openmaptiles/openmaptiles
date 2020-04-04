-- etldoc: ne_50m_urban_areas -> landuse_z4
CREATE OR REPLACE VIEW landuse_z4 AS (
    SELECT NULL::bigint AS osm_id, geometry, 'residential'::text AS landuse, NULL::text AS amenity, NULL::text AS leisure, NULL::text AS tourism, NULL::text AS place, NULL::text AS waterway
    FROM ne_50m_urban_areas
    WHERE scalerank <= 2
);

-- etldoc: ne_50m_urban_areas -> landuse_z5
CREATE OR REPLACE VIEW landuse_z5 AS (
    SELECT NULL::bigint AS osm_id, geometry, 'residential'::text AS landuse, NULL::text AS amenity, NULL::text AS leisure, NULL::text AS tourism, NULL::text AS place, NULL::text AS waterway
    FROM ne_50m_urban_areas
);

-- etldoc: osm_landuse_polygon_gen7 -> landuse_z6
CREATE OR REPLACE VIEW landuse_z6 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, tourism, place, waterway
    FROM osm_landuse_polygon_gen7
);

-- etldoc: osm_landuse_polygon_gen6 -> landuse_z8
CREATE OR REPLACE VIEW landuse_z8 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, tourism, place, waterway
    FROM osm_landuse_polygon_gen6
);

-- etldoc: osm_landuse_polygon_gen5 -> landuse_z9
CREATE OR REPLACE VIEW landuse_z9 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, tourism, place, waterway
    FROM osm_landuse_polygon_gen5
);

-- etldoc: osm_landuse_polygon_gen4 -> landuse_z10
CREATE OR REPLACE VIEW landuse_z10 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, tourism, place, waterway
    FROM osm_landuse_polygon_gen4
);

-- etldoc: osm_landuse_polygon_gen3 -> landuse_z11
CREATE OR REPLACE VIEW landuse_z11 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, tourism, place, waterway
    FROM osm_landuse_polygon_gen3
);

-- etldoc: osm_landuse_polygon_gen2 -> landuse_z12
CREATE OR REPLACE VIEW landuse_z12 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, tourism, place, waterway
    FROM osm_landuse_polygon_gen2
);

-- etldoc: osm_landuse_polygon_gen1 -> landuse_z13
CREATE OR REPLACE VIEW landuse_z13 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, tourism, place, waterway
    FROM osm_landuse_polygon_gen1
);

-- etldoc: osm_landuse_polygon -> landuse_z14
CREATE OR REPLACE VIEW landuse_z14 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, tourism, place, waterway
    FROM osm_landuse_polygon
);

-- etldoc: layer_landuse[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_landuse |<z4> z4|<z5>z5|<z6>z6|<z7>z7| <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11|<z12> z12|<z13> z13|<z14> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_landuse(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text) AS $$
    SELECT osm_id, geometry,
        COALESCE(
            NULLIF(landuse, ''),
            NULLIF(amenity, ''),
            NULLIF(leisure, ''),
            NULLIF(tourism, ''),
            NULLIF(place, ''),
            NULLIF(waterway, '')
        ) AS class
        FROM (
        -- etldoc: landuse_z4 -> layer_landuse:z4
        SELECT * FROM landuse_z4
        WHERE zoom_level = 4
        UNION ALL
        -- etldoc: landuse_z5 -> layer_landuse:z5
        SELECT * FROM landuse_z5
        WHERE zoom_level = 5
        UNION ALL
        -- etldoc: landuse_z6 -> layer_landuse:z6
        -- etldoc: landuse_z6 -> layer_landuse:z7
        SELECT * FROM landuse_z6 WHERE zoom_level BETWEEN 6 AND 7
        UNION ALL
        -- etldoc: landuse_z8 -> layer_landuse:z8
        SELECT * FROM landuse_z8 WHERE zoom_level = 8
        UNION ALL
        -- etldoc: landuse_z9 -> layer_landuse:z9
        SELECT * FROM landuse_z9 WHERE zoom_level = 9
        UNION ALL
        -- etldoc: landuse_z10 -> layer_landuse:z10
        SELECT * FROM landuse_z10 WHERE zoom_level = 10
        UNION ALL
        -- etldoc: landuse_z11 -> layer_landuse:z11
        SELECT * FROM landuse_z11 WHERE zoom_level = 11
        UNION ALL
        -- etldoc: landuse_z12 -> layer_landuse:z12
        SELECT * FROM landuse_z12 WHERE zoom_level = 12
        UNION ALL
        -- etldoc: landuse_z13 -> layer_landuse:z13
        SELECT * FROM landuse_z13 WHERE zoom_level = 13
        UNION ALL
        -- etldoc: landuse_z14 -> layer_landuse:z14
        SELECT * FROM landuse_z14 WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox;
$$
LANGUAGE SQL
IMMUTABLE PARALLEL SAFE;
