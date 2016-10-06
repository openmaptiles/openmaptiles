CREATE OR REPLACE VIEW urban_z5 AS (
    SELECT geom, scalerank
    FROM ne_50m_urban_areas
);

CREATE OR REPLACE VIEW urban_z6 AS (
    SELECT geom, scalerank
    FROM ne_10m_urban_areas
);
