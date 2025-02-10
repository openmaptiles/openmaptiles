CREATE OR REPLACE FUNCTION water_class(waterway text, water text, leisure text) RETURNS text AS
$$
SELECT CASE
           WHEN water IN ('river', 'canal', 'stream', 'ditch', 'drain') THEN 'river'
           %%FIELD_MAPPING: class %%
           ELSE 'lake'
           END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;




CREATE OR REPLACE FUNCTION waterway_brunnel(is_bridge bool, is_tunnel bool) RETURNS text AS
$$
SELECT CASE
           WHEN is_bridge THEN 'bridge'
           WHEN is_tunnel THEN 'tunnel'
           END;
$$ LANGUAGE SQL IMMUTABLE
                STRICT
                PARALLEL SAFE;







DROP MATERIALIZED VIEW IF EXISTS water_z0 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z1 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z2 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z3 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z4 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z5 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z6 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z7 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z8 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z9 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z10 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z11 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS water_z12 CASCADE;



CREATE MATERIALIZED VIEW water_z7 AS
(
-- etldoc:  osm_ocean_polygon_gen_z7 ->  water_z7
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z7
UNION ALL
-- etldoc:  osm_water_polygon_gen_z7 ->  water_z7
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z7
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z7 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z8 AS
(
-- etldoc:  osm_ocean_polygon_gen_z8 ->  water_z8
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z8
UNION ALL
-- etldoc:  osm_water_polygon_gen_z8 ->  water_z8
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z8
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z8 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z9 AS
(
-- etldoc:  osm_ocean_polygon_gen_z9 ->  water_z9
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z9
UNION ALL
-- etldoc:  osm_water_polygon_gen_z9 ->  water_z9
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z9
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z9 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z10 AS
(
-- etldoc:  osm_ocean_polygon_gen_z10 ->  water_z10
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z10
UNION ALL
-- etldoc:  osm_water_polygon_gen_z10 ->  water_z10
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z10
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z10 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z11 AS
(
-- etldoc:  osm_ocean_polygon_gen_z11 ->  water_z11
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z11
UNION ALL
-- etldoc:  osm_water_polygon_gen_z11 ->  water_z11
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z11
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z11 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z12 AS
(
-- etldoc:  osm_ocean_polygon_union ->  water_z12
SELECT NULL::integer AS id,
       (ST_Dump(geometry)).geom AS geometry,
       'ocean'::text AS class,
       NULL::boolean AS is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_union
UNION ALL
-- etldoc:  osm_water_polygon ->  water_z12
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       is_bridge,
       is_tunnel
FROM osm_water_polygon
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z12 USING gist(geometry);

CREATE MATERIALIZED VIEW water_z6 AS
(
-- etldoc:  osm_ocean_polygon_gen_z6 ->  water_z6
SELECT NULL::integer AS id,
    ST_MakeValid(
        ST_SnapToGrid(
            ST_SimplifyVW(
                ST_Buffer(
                    ST_SnapToGrid(
                        ST_Buffer(geometry, -0.004, 1),
                        0.004),
                    0.004,
                    1
                ),
                power(zres(6),2)  
            ),
            0.004
        )
    ) AS geometry,
    'ocean'::text AS class,
    NULL::boolean AS is_intermittent,
    NULL::boolean AS is_bridge,
    NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z6
UNION ALL
-- etldoc:  osm_water_polygon_gen_z6 ->  water_z6
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z6
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z6 USING gist(geometry);


CREATE MATERIALIZED VIEW water_z5 AS
(
-- etldoc:  osm_ocean_polygon_gen_z5 ->  water_z5
SELECT NULL::integer AS id,
    ST_MakeValid(
        ST_SnapToGrid(
            ST_SimplifyVW(
                ST_Buffer(
                    ST_SnapToGrid(
                        ST_Buffer(geometry, -0.008, 1),
                        0.008),
                    0.008,
                    1
                ),
                power(zres(5),2)  
            ),
            0.008
        )
    ) AS geometry,
    'ocean'::text AS class,
    NULL::boolean AS is_intermittent,
    NULL::boolean AS is_bridge,
    NULL::boolean AS is_tunnel
FROM osm_ocean_polygon_gen_z6
WHERE ST_Area(geometry) > power(zres(4),2)
UNION ALL
-- etldoc:  osm_water_polygon_gen_z5 ->  water_z4
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z5
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z5 USING gist(geometry);



CREATE MATERIALIZED VIEW water_z4 AS
(
-- etldoc:  osm_ocean_polygon_gen_z4 ->  water_z4
SELECT NULL::integer AS id,
    ST_MakeValid(
        ST_SnapToGrid(
            ST_SimplifyVW(
                ST_Buffer(
                    ST_SnapToGrid(
                        ST_Buffer(geometry, -0.016, 1),
                        0.016),
                    0.016,
                    1
                ),
                power(zres(4),2)
            ),
            0.016
        )  
    ) AS geometry,
    'ocean'::text AS class,
    NULL::boolean AS is_intermittent,
    NULL::boolean AS is_bridge,
    NULL::boolean AS is_tunnel
FROM water_z5
WHERE ST_Area(geometry) > power(zres(3),2)
UNION ALL
-- etldoc:  osm_water_polygon_gen_z4 ->  water_z3
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z4
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z4 USING gist(geometry);


CREATE MATERIALIZED VIEW water_z3 AS
(
-- etldoc:  osm_ocean_polygon_gen_z3 ->  water_z3
SELECT NULL::integer AS id,
    ST_MakeValid(
        ST_SnapToGrid(
            ST_SimplifyVW(
                ST_Buffer(
                    ST_SnapToGrid(
                        ST_Buffer(geometry, -0.032, 1),
                        0.032),
                    0.032,
                    1
                ),
                power(zres(3),2)
            ),
            0.032
        )
    ) AS geometry,
    'ocean'::text AS class,
    NULL::boolean AS is_intermittent,
    NULL::boolean AS is_bridge,
    NULL::boolean AS is_tunnel
FROM water_z4
WHERE ST_Area(geometry) > power(zres(2),2)
UNION ALL
-- etldoc:  osm_water_polygon_gen_z3 ->  water_z2
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z3
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z3 USING gist(geometry);


CREATE MATERIALIZED VIEW water_z2 AS
(
-- etldoc:  osm_ocean_polygon_gen_z2 ->  water_z2
SELECT NULL::integer AS id,
    ST_MakeValid(
        ST_SnapToGrid(
            ST_SimplifyVW(
                ST_Buffer(
                    ST_SnapToGrid(
                        ST_Buffer(geometry, -0.064, 1),
                        0.064),
                    0.064,
                    1
                ),
                power(zres(2),2)
            ),
            0.064 
        )
    ) AS geometry,
    'ocean'::text AS class,
    NULL::boolean AS is_intermittent,
    NULL::boolean AS is_bridge,
    NULL::boolean AS is_tunnel
FROM water_z3
WHERE ST_Area(geometry) > power(zres(1),2)
UNION ALL
-- etldoc:  osm_water_polygon_gen_z2 ->  water_z1
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z2
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z2 USING gist(geometry);


CREATE MATERIALIZED VIEW water_z1 AS
(
-- etldoc:  osm_ocean_polygon_gen_z1 ->  water_z1
SELECT NULL::integer AS id,
    ST_MakeValid(
        ST_SnapToGrid(
            ST_SimplifyVW(
                ST_Buffer(
                    ST_SnapToGrid(
                        ST_Buffer(geometry, -0.128, 1),
                        0.128),
                    0.128,
                    1
                ),
                power(zres(1),2)
            ),
            0.128
        )
    ) AS geometry,
    'ocean'::text AS class,
    NULL::boolean AS is_intermittent,
    NULL::boolean AS is_bridge,
    NULL::boolean AS is_tunnel
FROM water_z2
WHERE ST_Area(geometry) > power(zres(0),2)
UNION ALL
-- etldoc:  osm_water_polygon_gen_z1 ->  water_z0
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z1
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z1 USING gist(geometry);



CREATE MATERIALIZED VIEW water_z0 AS
(
-- etldoc:  osm_ocean_polygon_gen_z0 ->  water_z0
SELECT NULL::integer AS id,
    ST_MakeValid(
        ST_SnapToGrid(
            ST_SimplifyVW(
                ST_Buffer(
                    ST_SnapToGrid(
                        ST_Buffer(geometry,  -0.256, 1),
                        0.256),
                    0.256,
                    1
                ),
                power(zres(0),2)
            ),
            0.256 
        )
    ) AS geometry,
    'ocean'::text AS class,
    NULL::boolean AS is_intermittent,
    NULL::boolean AS is_bridge,
    NULL::boolean AS is_tunnel
FROM water_z1
UNION ALL
-- etldoc:  osm_water_polygon_gen_z1 ->  water_z0
SELECT osm_id AS id,
       (ST_Dump(geometry)).geom AS geometry,
       water_class(waterway, water, leisure) AS class,
       is_intermittent,
       NULL::boolean AS is_bridge,
       NULL::boolean AS is_tunnel
FROM osm_water_polygon_gen_z1
WHERE "natural" != 'bay'
    );
CREATE INDEX ON water_z0 USING gist(geometry);



-- etldoc: layer_water [shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_water |<z0> z0|<z1>z1|<z2>z2|<z3>z3 |<z4> z4|<z5>z5|<z6>z6|<z7>z7| <z8> z8 |<z9> z9 |<z10> z10 |<z11> z11 |<z12> z12+" ] ;

CREATE OR REPLACE FUNCTION layer_water(bbox geometry, zoom_level int)
    RETURNS TABLE
            (
                id           bigint,
                geometry     geometry,
                class        text,
                brunnel      text,
                intermittent int
            )
AS
$$
SELECT id,
       geometry,
       class::text,
       waterway_brunnel(is_bridge, is_tunnel) AS brunnel,
       is_intermittent::int AS intermittent
FROM (
         -- etldoc: water_z0 ->  layer_water:z0
         SELECT *
         FROM water_z0
         WHERE zoom_level = 0
         UNION ALL
         -- etldoc: water_z1 ->  layer_water:z1
         SELECT *
         FROM water_z1
         WHERE zoom_level = 1
         UNION ALL
         -- etldoc: water_z2 ->  layer_water:z2
         SELECT *
         FROM water_z2
         WHERE zoom_level = 2
         UNION ALL
         -- etldoc: water_z3 ->  layer_water:z3
         SELECT *
         FROM water_z3
         WHERE zoom_level = 3
         UNION ALL
         -- etldoc: water_z4 ->  layer_water:z4
         SELECT *
         FROM water_z4
         WHERE zoom_level = 4
         UNION ALL
         -- etldoc: water_z5 ->  layer_water:z5
         SELECT *
         FROM water_z5
         WHERE zoom_level = 5
         UNION ALL
         -- etldoc: water_z6 ->  layer_water:z6
         SELECT *
         FROM water_z6
         WHERE zoom_level = 6
         UNION ALL
         -- etldoc: water_z7 ->  layer_water:z7
         SELECT *
         FROM water_z7
         WHERE zoom_level = 7
         UNION ALL
         -- etldoc: water_z8 ->  layer_water:z8
         SELECT *
         FROM water_z8
         WHERE zoom_level = 8
         UNION ALL
         -- etldoc: water_z9 ->  layer_water:z9
         SELECT *
         FROM water_z9
         WHERE zoom_level = 9
         UNION ALL
         -- etldoc: water_z10 ->  layer_water:z10
         SELECT *
         FROM water_z10
         WHERE zoom_level = 10
         UNION ALL
         -- etldoc: water_z11 ->  layer_water:z11
         SELECT *
         FROM water_z11
         WHERE zoom_level = 11
         UNION ALL
         -- etldoc: water_z12 ->  layer_water:z12
         SELECT *
         FROM water_z12
         WHERE zoom_level >= 12
     ) AS zoom_levels
WHERE geometry && bbox;
$$ LANGUAGE SQL STABLE
                -- STRICT
                PARALLEL SAFE;
