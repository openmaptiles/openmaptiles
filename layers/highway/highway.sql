CREATE OR REPLACE FUNCTION ne_highway(type VARCHAR) RETURNS VARCHAR AS $$
  SELECT CASE type
    WHEN 'Major Highway' THEN 'motorway'
    WHEN 'Secondary Highway' THEN 'trunk'
    WHEN 'Road' THEN 'primary'
    ELSE type
  END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE TABLE IF NOT EXISTS ne_10m_global_roads AS (
    SELECT geom, scalerank, ne_highway(type) AS highway
    FROM ne_10m_roads
    WHERE continent <> 'North America'
      AND featurecla = 'Road'
      AND type IN ('Major Highway', 'Secondary Highway', 'Road')
    UNION ALL
    SELECT geom, scalerank, ne_highway(type) AS highway
    FROM ne_10m_roads_north_america
    WHERE type IN ('Major Highway', 'Secondary Highway', 'Road')
);

CREATE INDEX IF NOT EXISTS ne_10m_global_roads_geom_idx ON ne_10m_global_roads USING gist(geom);
CREATE INDEX IF NOT EXISTS ne_10m_global_roads_scalerank_idx ON ne_10m_global_roads(scalerank);

CREATE OR REPLACE VIEW highway_z4 AS (
    SELECT geom, highway
    FROM ne_10m_global_roads
    WHERE scalerank <= 5
);

CREATE OR REPLACE VIEW highway_z5 AS (
    SELECT geom, highway
    FROM ne_10m_global_roads
    WHERE scalerank <= 6
);

CREATE OR REPLACE VIEW highway_z6 AS (
    SELECT geom, highway
    FROM ne_10m_global_roads
    WHERE scalerank <= 7
);

CREATE OR REPLACE VIEW highway_z7 AS (
    SELECT geom, highway
    FROM ne_10m_global_roads
    WHERE scalerank <= 7
);

CREATE TABLE IF NOT EXISTS highway_z8 AS (
    SELECT ST_Simplify(geometry, 200) AS geom, highway
    FROM osm_highway_linestring
    WHERE highway IN ('motorway','trunk')
);
CREATE INDEX IF NOT EXISTS highway_z8_geom_idx ON highway_z8 USING gist(geom);

CREATE TABLE IF NOT EXISTS highway_z9 AS (
    SELECT ST_Simplify(geometry, 120) AS geom, highway
    FROM osm_highway_linestring
    WHERE highway IN ('motorway','trunk', 'primary')
);
CREATE INDEX IF NOT EXISTS highway_z9_geom_idx ON highway_z9 USING gist(geom);

CREATE TABLE IF NOT EXISTS highway_z10 AS (
    SELECT ST_Simplify(geometry, 50) AS geom, highway
    FROM osm_highway_linestring
    WHERE highway IN ('motorway','trunk', 'primary', 'secondary')
);
CREATE INDEX IF NOT EXISTS highway_z10_geom_idx ON highway_z10 USING gist(geom);

CREATE TABLE IF NOT EXISTS highway_z11 AS (
    SELECT ST_Simplify(geometry, 20) AS geom, highway
    FROM osm_highway_linestring
    WHERE highway IN ('motorway','trunk', 'primary', 'secondary', 'tertiary')
);
CREATE INDEX IF NOT EXISTS highway_z11_geom_idx ON highway_z11 USING gist(geom);

CREATE OR REPLACE VIEW highway_z12 AS (
    SELECT geometry AS geom, highway
    FROM osm_highway_linestring
    WHERE highway IN ('motorway','trunk','primary', 'secondary', 'tertiary', 'minor')
);

CREATE OR REPLACE VIEW highway_z13 AS (
    SELECT geometry AS geom, highway
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
    SELECT geometry AS geom, highway
    FROM osm_highway_linestring
);

CREATE OR REPLACE FUNCTION layer_highway(bbox geometry, zoom_level int)
RETURNS TABLE(geom geometry, highway text) AS $$
    SELECT geom, highway FROM (
        SELECT * FROM highway_z4 WHERE zoom_level BETWEEN 4 AND 5
        UNION ALL
        SELECT * FROM highway_z5 WHERE zoom_level = 5
        UNION ALL
        SELECT * FROM highway_z6 WHERE zoom_level = 6
        UNION ALL
        SELECT * FROM highway_z7 WHERE zoom_level = 7
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
    WHERE geom && bbox;
$$ LANGUAGE SQL IMMUTABLE;
