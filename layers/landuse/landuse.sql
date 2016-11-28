
CREATE OR REPLACE FUNCTION landuse_class(landuse TEXT, amenity TEXT, leisure TEXT) RETURNS TEXT AS $$
    SELECT CASE
         WHEN amenity IN ('school', 'university', 'kindergarten', 'college', 'library') THEN 'school'
         WHEN landuse IN('hospital', 'railway', 'cemetery', 'military', 'residential') THEN landuse
         ELSE NULL
	 END;
$$ LANGUAGE SQL IMMUTABLE;

-- etldoc: ne_50m_urban_areas -> landuse_z4
CREATE OR REPLACE VIEW landuse_z4 AS (
    SELECT NULL::bigint AS osm_id, geom AS geometry, 'residential'::text AS landuse, NULL::text AS amenity, NULL::text AS leisure, scalerank
    FROM ne_50m_urban_areas
    WHERE scalerank <= 2
);

-- etldoc: ne_50m_urban_areas -> landuse_z5
CREATE OR REPLACE VIEW landuse_z5 AS (
    SELECT NULL::bigint AS osm_id, geom AS geometry, 'residential'::text AS landuse, NULL::text AS amenity, NULL::text AS leisure, scalerank
    FROM ne_50m_urban_areas
);

-- etldoc: ne_10m_urban_areas -> landuse_z6
CREATE OR REPLACE VIEW landuse_z6 AS (
    SELECT NULL::bigint AS osm_id, geom AS geometry, 'residential'::text AS landuse, NULL::text AS amenity, NULL::text AS leisure, scalerank
    FROM ne_10m_urban_areas
);

-- etldoc: osm_landuse_polygon_gen1 -> landuse_z12
CREATE OR REPLACE VIEW landuse_z12 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, NULL::int as scalerank FROM osm_landuse_polygon_gen1
);

-- etldoc: osm_landuse_polygon -> landuse_z13
CREATE OR REPLACE VIEW landuse_z13 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, NULL::int as scalerank FROM osm_landuse_polygon
    WHERE ST_Area(geometry) > 60000
);

-- etldoc: osm_landuse_polygon -> landuse_z14
CREATE OR REPLACE VIEW landuse_z14 AS (
    SELECT osm_id, geometry, landuse, amenity, leisure, NULL::int as scalerank FROM osm_landuse_polygon
);

-- etldoc: layer_landuse[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_landuse |<z4> z4|<z5>z5|<z6>z6|<z7>z7| <z8> z8 |<z9> z9 |<z10> z10 |<z12> z12|<z13> z13|<z14_> z14_" ] ;

CREATE OR REPLACE FUNCTION layer_landuse(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text, subclass text) AS $$
    SELECT osm_id, geometry,
        landuse_class(landuse, amenity, leisure) AS class,
        COALESCE(NULLIF(landuse, ''), NULLIF(amenity, ''), NULLIF(leisure, '')) AS subclass
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
        -- etldoc: landuse_z6 -> layer_landuse:z8
        -- etldoc: landuse_z6 -> layer_landuse:z9
        -- etldoc: landuse_z6 -> layer_landuse:z10
        SELECT * FROM landuse_z6
        WHERE zoom_level BETWEEN 6 AND 10 AND scalerank-1 <= zoom_level
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
$$ LANGUAGE SQL IMMUTABLE;

