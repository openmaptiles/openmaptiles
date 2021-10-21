-- Post-processing imposm-generated tables

ALTER TABLE osm_park_polygon_geometry
    ADD COLUMN IF NOT EXISTS attr jsonb,
    ADD COLUMN IF NOT EXISTS centroid geometry,
    ADD COLUMN IF NOT EXISTS geom_z13 geometry,
    ADD COLUMN IF NOT EXISTS geom_z12 geometry,
    ADD COLUMN IF NOT EXISTS geom_z11 geometry,
    ADD COLUMN IF NOT EXISTS geom_z10 geometry,
    ADD COLUMN IF NOT EXISTS geom_z9 geometry,
    ADD COLUMN IF NOT EXISTS geom_z8 geometry,
    ADD COLUMN IF NOT EXISTS geom_z7 geometry,
    ADD COLUMN IF NOT EXISTS geom_z6 geometry,
    ADD COLUMN IF NOT EXISTS geom_z5 geometry;

CREATE INDEX IF NOT EXISTS osm_park_polygon_centroid_idx ON osm_park_polygon_geometry USING gist (centroid);

CREATE INDEX IF NOT EXISTS osm_park_polygon_geom_z13_idx ON osm_park_polygon_geometry USING gist (geom_z13)
    WHERE geom_z13 IS NOT NULL;
CREATE INDEX IF NOT EXISTS osm_park_polygon_geom_z13_idx ON osm_park_polygon_geometry USING gist (geom_z12)
    WHERE geom_z12 IS NOT NULL;
CREATE INDEX IF NOT EXISTS osm_park_polygon_geom_z13_idx ON osm_park_polygon_geometry USING gist (geom_z11)
    WHERE geom_z11 IS NOT NULL;
CREATE INDEX IF NOT EXISTS osm_park_polygon_geom_z13_idx ON osm_park_polygon_geometry USING gist (geom_z10)
    WHERE geom_z10 IS NOT NULL;
CREATE INDEX IF NOT EXISTS osm_park_polygon_geom_z13_idx ON osm_park_polygon_geometry USING gist (geom_z9)
    WHERE geom_z9 IS NOT NULL;
CREATE INDEX IF NOT EXISTS osm_park_polygon_geom_z13_idx ON osm_park_polygon_geometry USING gist (geom_z8)
    WHERE geom_z8 IS NOT NULL;
CREATE INDEX IF NOT EXISTS osm_park_polygon_geom_z13_idx ON osm_park_polygon_geometry USING gist (geom_z7)
    WHERE geom_z7 IS NOT NULL;
CREATE INDEX IF NOT EXISTS osm_park_polygon_geom_z13_idx ON osm_park_polygon_geometry USING gist (geom_z6)
    WHERE geom_z6 IS NOT NULL;
CREATE INDEX IF NOT EXISTS osm_park_polygon_geom_z13_idx ON osm_park_polygon_geometry USING gist (geom_z5)
    WHERE geom_z5 IS NOT NULL;

-- etldoc: osm_park_polygon_geometry -> osm_park_polygon_geometry
UPDATE osm_park_polygon_geometry
   SET centroid = st_centroid(geometry);

-- etldoc: osm_park_polygon_tags -> osm_park_polygon_geometry
UPDATE osm_park_polygon_geometry g
   SET attr = park_tile_attr(to_jsonb(t))
  FROM osm_park_polygon_tags t
 WHERE g.osm_id=t.osm_id;
