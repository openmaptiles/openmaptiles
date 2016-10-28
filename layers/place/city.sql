CREATE OR REPLACE FUNCTION layer_city(bbox geometry, zoom_level int, pixel_width numeric)
RETURNS TABLE(osm_id bigint, geometry geometry, name text, name_en text, place text, scalerank int) AS $$
    SELECT osm_id, geometry, name, name_en, place, scalerank
    FROM osm_place_point
    WHERE geometry && bbox
      AND ((zoom_level = 2 AND scalerank = 0)
        OR (zoom_level BETWEEN 3 AND 7 AND scalerank < zoom_level)
      )
    UNION ALL
    SELECT osm_id, geometry, name, name_en, place, scalerank FROM (
        SELECT osm_id, geometry, name, name_en, place, scalerank,
			row_number() OVER (
				PARTITION BY LabelGrid(geometry, 150 * pixel_width)
				ORDER BY place::place_subclass ASC NULLS LAST,
				population DESC NULLS LAST,
				length(name) DESC
			) AS gridrank
        FROM osm_place_point
        WHERE geometry && bbox
          AND ((zoom_level BETWEEN 8 AND 9 AND place::place_subclass <= 'town'::place_subclass)
            OR (zoom_level = 10 AND place::place_subclass <= 'village'::place_subclass)
            OR (zoom_level BETWEEN 11 AND 13 AND place::place_subclass <= 'suburb'::place_subclass)
            OR (zoom_level >= 14)
          )
    ) AS ranked_places
    WHERE (zoom_level = 8 AND gridrank <= 4)
       OR (zoom_level BETWEEN 9 AND 12 AND gridrank <= 9)
       OR (zoom_level >= 13);
$$ LANGUAGE SQL IMMUTABLE;
