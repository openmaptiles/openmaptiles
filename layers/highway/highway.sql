CREATE OR REPLACE FUNCTION highway_brunnel(is_bridge boolean, is_tunnel boolean) RETURNS TEXT AS $$
    SELECT CASE
         WHEN is_bridge THEN 'bridge'
         WHEN is_tunnel THEN 'tunnel'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION highway_class(highway TEXT) RETURNS TEXT AS $$
    SELECT CASE
        WHEN highway IN ('unclassified', 'residential', 'living_street', 'road', 'track', 'service') THEN 'minor'
        WHEN highway IN ('primary', 'primary_link') THEN 'primary'
        WHEN highway IN ('secondary', 'secondary_link') THEN 'secondary'
        WHEN highway IN ('tertiary', 'tertiary_link') THEN 'tertiary'
        WHEN highway IN ('motorway', 'motorway_link') THEN 'motorway'
        WHEN highway IN ('trunk', 'trunk_link') THEN 'trunk'
        WHEN highway IN ('pedestrian', 'path', 'footway', 'cycleway', 'steps') THEN 'path'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION ne_highway(type VARCHAR) RETURNS VARCHAR AS $$
  SELECT CASE type
    WHEN 'Major Highway' THEN 'motorway'
    WHEN 'Secondary Highway' THEN 'trunk'
    WHEN 'Road' THEN 'primary'
    ELSE type
  END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE TABLE IF NOT EXISTS ne_10m_global_roads AS (
    SELECT geom AS geometry, scalerank, ne_highway(type) AS highway, NULL::boolean AS is_tunnel, NULL::boolean AS is_bridge, 0::int as z_order
    FROM ne_10m_roads
    WHERE continent <> 'North America'
      AND featurecla = 'Road'
      AND type IN ('Major Highway', 'Secondary Highway', 'Road')
    UNION ALL
    SELECT geom AS geometry, scalerank, ne_highway(type) AS highway, NULL::boolean AS is_tunnel, NULL::boolean AS is_bridge, 0::int as z_order
    FROM ne_10m_roads_north_america
    WHERE type IN ('Major Highway', 'Secondary Highway', 'Road')
);

CREATE INDEX IF NOT EXISTS ne_10m_global_roads_geometry_idx ON ne_10m_global_roads USING gist(geometry);
CREATE INDEX IF NOT EXISTS ne_10m_global_roads_scalerank_idx ON ne_10m_global_roads(scalerank);

CREATE OR REPLACE VIEW highway_z4 AS (
    SELECT geometry, highway, is_tunnel, is_bridge, z_order
    FROM ne_10m_global_roads
    WHERE scalerank <= 5
);

CREATE OR REPLACE VIEW highway_z5 AS (
    SELECT geometry, highway, is_tunnel, is_bridge, z_order
    FROM ne_10m_global_roads
    WHERE scalerank <= 6
);

CREATE OR REPLACE VIEW highway_z6 AS (
    SELECT geometry, highway, is_tunnel, is_bridge, z_order
    FROM ne_10m_global_roads
    WHERE scalerank <= 7
);

CREATE OR REPLACE VIEW highway_z8 AS (
    SELECT geometry, highway, is_tunnel, is_bridge, z_order
    FROM osm_highway_linestring_gen4
);

CREATE OR REPLACE VIEW highway_z9 AS (
    SELECT geometry, highway, is_tunnel, is_bridge, z_order
    FROM osm_highway_linestring_gen3
);

CREATE OR REPLACE VIEW highway_z10 AS (
    SELECT geometry, highway, is_tunnel, is_bridge, z_order
    FROM osm_highway_linestring_gen2
);

CREATE OR REPLACE VIEW highway_z11 AS (
    SELECT geometry, highway, is_tunnel, is_bridge, z_order
    FROM osm_highway_linestring_gen1
);

CREATE OR REPLACE VIEW highway_z12 AS (
    SELECT geometry, highway, is_tunnel, is_bridge, z_order
    FROM osm_highway_linestring
    WHERE highway IN ('motorway','trunk','primary', 'secondary', 'tertiary', 'minor')
);

CREATE OR REPLACE VIEW highway_z13 AS (
    SELECT geometry, highway, is_tunnel, is_bridge, z_order
    FROM osm_highway_linestring
    WHERE highway IN (
        'motorway',
        'motorway_link',
        'trunk',
        'trunk_link',
        'primary',
        'primary_link',
        'secondary',
        'secondary_link',
        'tertiary',
        'tertiary_link',
        'road',
        'living_street',
        'service',
        'residential'
    )
);

CREATE OR REPLACE VIEW highway_z14 AS (
    SELECT geometry, highway, is_tunnel, is_bridge, z_order
    FROM osm_highway_linestring
);

CREATE OR REPLACE FUNCTION layer_highway(bbox geometry, zoom_level int)
RETURNS TABLE(geometry geometry, class text, subclass text) AS $$
    SELECT geometry, highway_class(highway) AS class, highway AS subclass FROM (
        SELECT * FROM highway_z4 WHERE zoom_level BETWEEN 4 AND 5
        UNION ALL
        SELECT * FROM highway_z5 WHERE zoom_level = 5
        UNION ALL
        SELECT * FROM highway_z6 WHERE zoom_level BETWEEN 6 AND 7
        UNION ALL
        SELECT * FROM highway_z8 WHERE zoom_level = 8
        UNION ALL
        SELECT * FROM highway_z9 WHERE zoom_level = 9
        UNION ALL
        SELECT * FROM highway_z10 WHERE zoom_level = 10
        UNION ALL
        SELECT * FROM highway_z11 WHERE zoom_level = 11
        UNION ALL
        SELECT * FROM highway_z12 WHERE zoom_level = 12
        UNION ALL
        SELECT * FROM highway_z13 WHERE zoom_level = 13
        UNION ALL
        SELECT * FROM highway_z14 WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;
