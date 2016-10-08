CREATE OR REPLACE VIEW place_z2 AS (
	SELECT geom, name, 'settlement' AS class, 'city'::place AS rank, scalerank, pop_min AS population
    FROM ne_10m_populated_places
    WHERE  scalerank <= 0
);

CREATE OR REPLACE VIEW place_z3 AS (
	SELECT geom, name, 'settlement' AS class, 'city'::place AS rank, scalerank, pop_min AS population
    FROM ne_10m_populated_places
    WHERE  scalerank <= 2
);

CREATE OR REPLACE VIEW place_z4 AS (
	SELECT geom, name, 'settlement' AS class, 'city'::place AS rank, scalerank, pop_min AS population
    FROM ne_10m_populated_places
    WHERE  scalerank <= 5
);

CREATE OR REPLACE VIEW place_z5 AS (
	SELECT geom, name, 'settlement' AS class, 'city'::place AS rank, scalerank, pop_min AS population
    FROM ne_10m_populated_places
    WHERE  scalerank <= 6
);

CREATE OR REPLACE VIEW place_z6 AS (
	SELECT geom, name, 'settlement' AS class, 'city'::place AS rank, scalerank, pop_min AS population
    FROM ne_10m_populated_places
    WHERE  scalerank <= 7
);

CREATE OR REPLACE VIEW place_z7 AS (
	SELECT geom, name, 'settlement' AS class, 'city'::place AS rank, scalerank, pop_min AS population
    FROM ne_10m_populated_places
);

CREATE OR REPLACE VIEW place_z8 AS (
	SELECT way AS geom, name, class::text, rank, NULL::integer AS scalerank, population FROM place_point
    WHERE rank IN ('city', 'town')
);

CREATE OR REPLACE VIEW place_z10 AS (
	SELECT way AS geom, name, class::text, rank, NULL::integer AS scalerank, population FROM place_point
    WHERE rank IN ('city', 'town', 'village') OR class='subregion'
);

CREATE OR REPLACE VIEW place_z11 AS (
	SELECT way AS geom, name, class::text, rank, NULL::integer AS scalerank, population FROM place_point
    WHERE class IN ('subregion', 'settlement')
);

CREATE OR REPLACE VIEW place_z13 AS (
	SELECT way AS geom, name, class::text, rank, NULL::integer AS scalerank, population FROM place_point
);
