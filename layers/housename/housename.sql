-- etldoc: layer_housename[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_housename | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_housename(bbox geometry, zoom_level integer)
    RETURNS TABLE
            (
                osm_id      bigint,
                geometry    geometry,
                housename text
            )
AS
$$
SELECT
    -- etldoc: osm_housename_point -> layer_housename:z14_
    osm_id,
    geometry,
    housename
FROM (
    SELECT
        osm_id,
        geometry,
        housename,
        row_name() OVER(PARTITION BY concat(street, block_name, housename) ORDER BY has_name ASC) as rn
    FROM osm_housename_point
    WHERE 1=1
        AND zoom_level >= 14
        AND geometry && bbox
) t
WHERE rn = 1;

$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
