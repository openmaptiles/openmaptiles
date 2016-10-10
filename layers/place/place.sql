CREATE OR REPLACE VIEW place_z2 AS (
    SELECT geom, name, 'city' AS place, scalerank, pop_min AS population
    FROM ne_10m_populated_places
    WHERE  scalerank <= 0
);

CREATE OR REPLACE VIEW place_z3 AS (
    SELECT geom, name, 'city' AS place, scalerank, pop_min AS population
    FROM ne_10m_populated_places
    WHERE  scalerank <= 2
);

CREATE OR REPLACE VIEW place_z4 AS (
    SELECT geom, name, 'city' AS place, scalerank, pop_min AS population
    FROM ne_10m_populated_places
    WHERE  scalerank <= 5
);

CREATE OR REPLACE VIEW place_z5 AS (
    SELECT geom, name, 'city' AS place, scalerank, pop_min AS population
    FROM ne_10m_populated_places
    WHERE  scalerank <= 6
);

CREATE OR REPLACE VIEW place_z6 AS (
    SELECT geom, name, 'city' AS place, scalerank, pop_min AS population
    FROM ne_10m_populated_places
    WHERE  scalerank <= 7
);

CREATE OR REPLACE VIEW place_z7 AS (
    SELECT geom, name, 'city' AS place, scalerank, pop_min AS population
    FROM ne_10m_populated_places
);

CREATE OR REPLACE VIEW place_z8 AS (
    SELECT geometry AS geom, name, place, NULL::integer AS scalerank, population FROM osm_place_point
    WHERE place IN ('city', 'town')
);

CREATE OR REPLACE VIEW place_z10 AS (
    SELECT geometry AS geom, name, place, NULL::integer AS scalerank, population FROM osm_place_point
    WHERE place IN ('city', 'town', 'village') OR place='subregion'
);

CREATE OR REPLACE VIEW place_z11 AS (
    SELECT geometry AS geom, name, place, NULL::integer AS scalerank, population FROM osm_place_point
);

CREATE OR REPLACE VIEW place_z13 AS (
    SELECT geometry AS geom, name, place, NULL::integer AS scalerank, population FROM osm_place_point
);

CREATE OR REPLACE FUNCTION layer_place(bbox geometry, zoom_level int, pixel_width numeric)
RETURNS TABLE(geom geometry, name text, place text, scalerank int) AS $$
    SELECT geom, name, place, scalerank FROM (
        SELECT geom, name, place, scalerank,
        row_number() OVER (
            PARTITION BY LabelGrid(geom, 150 * pixel_width)
            ORDER BY scalerank ASC NULLS LAST,
            population DESC NULLS LAST,
            length(name) DESC
        ) AS gridrank
        FROM (
            SELECT * FROM place_z2
            WHERE zoom_level = 2
            UNION ALL
            SELECT * FROM place_z3
            WHERE zoom_level = 3
            UNION ALL
            SELECT * FROM place_z4
            WHERE zoom_level = 4
            UNION ALL
            SELECT * FROM place_z5
            WHERE zoom_level = 5
            UNION ALL
            SELECT * FROM place_z6
            WHERE zoom_level = 6
            UNION ALL
            SELECT * FROM place_z7
            WHERE zoom_level = 7
            UNION ALL
            SELECT * FROM place_z8
            WHERE zoom_level BETWEEN 8 AND 9
            UNION ALL
            SELECT * FROM place_z10
            WHERE zoom_level = 10
            UNION ALL
            SELECT * FROM place_z11
            WHERE zoom_level BETWEEN 11 AND 12
            UNION ALL
            SELECT * FROM place_z13
            WHERE zoom_level >= 13
        ) AS zoom_levels
        WHERE geom && bbox
    ) AS ranked_places
    WHERE
        zoom_level <= 7 OR
        (zoom_level = 8 AND gridrank <= 4) OR
        (zoom_level = 9 AND gridrank <= 9) OR
        (zoom_level = 10 AND gridrank <= 9) OR
        (zoom_level = 11 AND gridrank <= 9) OR
        (zoom_level = 12 AND gridrank <= 9) OR
        zoom_level >= 13;
$$ LANGUAGE SQL IMMUTABLE;
