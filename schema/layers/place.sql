CREATE OR REPLACE VIEW place_z3 AS (
	SELECT geom, name, 'settlement' AS class, 'city' AS rank, scalerank
    FROM ne_10m_populated_places
    WHERE  scalerank <= 2
);

CREATE OR REPLACE VIEW place_z4 AS (
	SELECT geom, name, 'settlement' AS class, 'city' AS rank, scalerank
    FROM ne_10m_populated_places
    WHERE  scalerank <= 5
);

CREATE OR REPLACE VIEW place_z5 AS (
	SELECT geom, name, 'settlement' AS class, 'city' AS rank, scalerank
    FROM ne_10m_populated_places
    WHERE  scalerank <= 6
);

CREATE OR REPLACE VIEW place_z6 AS (
	SELECT geom, name, 'settlement' AS class, 'city' AS rank, scalerank
    FROM ne_10m_populated_places
    WHERE  scalerank <= 7
);

CREATE OR REPLACE VIEW place_z7 AS (
	SELECT geom, name, 'settlement' AS class, 'city' AS rank, scalerank FROM ne_10m_populated_places
);

CREATE OR REPLACE VIEW place_z8 AS (
	SELECT way AS geom, name, class::text, rank::text, NULL::integer AS scalerank FROM place_point
    WHERE rank IN ('city', 'town')
);
