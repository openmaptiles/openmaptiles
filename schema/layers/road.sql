CREATE OR REPLACE VIEW ne_10m_global_roads AS (
    SELECT geom, scalerank, featurecla as featureclass, type
    FROM ne_10m_roads WHERE continent <> 'North America'
    UNION ALL
    SELECT geom, scalerank, class as featureclass, type
    FROM ne_10m_roads_north_america
);

CREATE OR REPLACE VIEW road_z4 AS (
    SELECT *
    FROM ne_10m_global_roads
    WHERE scalerank <= 4
);

CREATE OR REPLACE VIEW road_z5 AS (
    SELECT *
    FROM ne_10m_global_roads
    WHERE scalerank <= 5
);

CREATE OR REPLACE VIEW road_z6 AS (
    SELECT *
    FROM ne_10m_global_roads
    WHERE scalerank <= 6
);

CREATE OR REPLACE VIEW road_z7 AS (
    SELECT *
    FROM ne_10m_global_roads
    WHERE scalerank <= 7
);
