CREATE OR REPLACE VIEW place_z2 AS (
    SELECT osm_id, geometry, name, name_en, place, scalerank, population
    FROM osm_important_place_point
    WHERE scalerank <= 0
);

CREATE OR REPLACE VIEW place_z3 AS (
    SELECT osm_id, geometry, name, name_en, place, scalerank, population
    FROM osm_important_place_point
    WHERE scalerank <= 2
);

CREATE OR REPLACE VIEW place_z4 AS (
    SELECT osm_id, geometry, name, name_en, place, scalerank, population
    FROM osm_important_place_point
    WHERE scalerank <= 5
);

CREATE OR REPLACE VIEW place_z5 AS (
    SELECT osm_id, geometry, name, name_en, place, scalerank, population
    FROM osm_important_place_point
    WHERE scalerank <= 6
);

CREATE OR REPLACE VIEW place_z6 AS (
    SELECT osm_id, geometry, name, name_en, place, scalerank, population
    FROM osm_important_place_point
    WHERE scalerank <= 7
);

CREATE OR REPLACE VIEW place_z7 AS (
    SELECT osm_id, geometry, name, name_en, place, scalerank, population
    FROM osm_important_place_point
);

CREATE OR REPLACE VIEW place_z8 AS (
    SELECT osm_id, geometry, name, name_en, place, NULL::integer AS scalerank, population FROM osm_place_point
    WHERE place IN ('city', 'town')
);

CREATE OR REPLACE VIEW place_z10 AS (
    SELECT osm_id, geometry, name, name_en, place, NULL::integer AS scalerank, population FROM osm_place_point
    WHERE place IN ('city', 'town', 'village') OR place='subregion'
);

CREATE OR REPLACE VIEW place_z11 AS (
    SELECT osm_id, geometry, name, name_en, place, NULL::integer AS scalerank, population FROM osm_place_point
    WHERE place IN ('city', 'town', 'village', 'suburb')
);

CREATE OR REPLACE VIEW place_z13 AS (
    SELECT osm_id, geometry, name, name_en, place, NULL::integer AS scalerank, population FROM osm_place_point
    WHERE place IN ('city', 'town', 'village', 'suburb')
);

CREATE OR REPLACE FUNCTION layer_place(bbox geometry, zoom_level int, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, place text, abbrev text, postal text, scalerank int) AS $$
    SELECT osm_id, geometry, name, name AS name_en, 'country' AS place, abbrev, postal, scalerank FROM layer_country(bbox, zoom_level)
    UNION ALL
    SELECT osm_id, geometry, name, name_en, 'state' AS place, abbrev, postal, scalerank FROM layer_state(bbox, zoom_level)
    UNION ALL
    SELECT osm_id, geometry, name, name_en, place, NULL AS abbrev, NULL AS postal, scalerank FROM (
        SELECT osm_id, geometry, name, name_en, place, scalerank,
        row_number() OVER (
            PARTITION BY LabelGrid(geometry, 150 * pixel_width)
            ORDER BY scalerank ASC NULLS LAST,
            population DESC NULLS LAST,
            length(name) DESC
        ) AS gridrank
        FROM (
            --Cities
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
        WHERE geometry && bbox
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
