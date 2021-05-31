-- etldoc: layer_motorway_junction[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_motorway_junction | <z9_> z9+" ] ;

CREATE OR REPLACE FUNCTION layer_motorway_junction(bbox geometry,
                                                   zoom_level integer,
                                                   pixel_width numeric)
    RETURNS TABLE
            (
                osm_id   bigint,
                geometry geometry,
                name     text,
                name_en  text,
                name_de  text,
                tags     hstore,
                ref      text
            )
AS
$$
SELECT
    -- etldoc: osm_motorway_junction -> layer_motorway_junction:z9_
    osm_id,
    geometry,
    name,
    COALESCE(NULLIF(name_en, ''), name) AS name_en,
    COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
    tags,
    ref
FROM osm_motorway_junction
WHERE geometry && bbox AND zoom_level >= 9;

$$ LANGUAGE SQL STABLE
                PARALLEL SAFE;
-- TODO: Check if the above can be made STRICT -- i.e. if pixel_width could be NULL
