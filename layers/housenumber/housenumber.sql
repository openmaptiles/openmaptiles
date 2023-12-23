-- etldoc: layer_housenumber[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_housenumber | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_housenumber(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                osm_id      bigint,
                geometry    geometry,
                housenumber text
            )
AS
$$
SELECT
    -- etldoc: osm_housenumber_point -> layer_housenumber:z14_
    osm_id,
    geometry,
    display_housenumber(housenumber)
FROM (
    SELECT
        osm_id,
        geometry,
        housenumber,
        row_number() OVER(PARTITION BY concat(street, block_number, housenumber) ORDER BY has_name ASC) as rn
    FROM osm_housenumber_point
    WHERE 1=1
        AND zoom_level >= 14
        AND geometry && bbox
) t
WHERE rn = 1;

$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
