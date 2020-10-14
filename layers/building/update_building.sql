DROP TRIGGER IF EXISTS trigger_refresh ON buildings.updates;
DROP TRIGGER IF EXISTS trigger_flag ON osm_building_polygon;

--creating aggregated building blocks with removed small polygons and small
--holes. Aggregated polygons are simplified.

--function returning recordset for matview
--returning recordset of buildings aggregates by zres 14, with removed small
--holes and with removed small buildings/blocks
--

CREATE OR REPLACE FUNCTION osm_building_block_gen1()
    RETURNS table
            (
                osm_id   bigint,
                geometry geometry
            )
AS
$$
DECLARE
    zres14 float := Zres(14);
    zres12 float := Zres(12);
BEGIN
    FOR osm_id, geometry IN
        WITH dta AS ( -- CTE is used because of optimization
            SELECT o.osm_id, o.geometry, ST_ClusterDBSCAN(o.geometry, eps := zres14, minpoints := 1) OVER () cid
            FROM osm_building_polygon o
        )
        SELECT (array_agg(dta.osm_id))[1]                                                                   osm_id,
               ST_Buffer(ST_MemUnion(ST_Buffer(dta.geometry, zres14, 'join=mitre')), -zres14, 'join=mitre') geometry
        FROM dta
        GROUP BY cid

        LOOP
            -- removing holes smaller than
            IF ST_NumInteriorRings(geometry) > 0 THEN -- only from geometries wih holes
                geometry := (
                    -- there are some multi-geometries in this layer
                    SELECT ST_Collect(gn)
                    FROM (
                             -- in some cases are "holes" NULL, because all holes are smaller than
                             SELECT COALESCE(
                                        -- exterior ring
                                            ST_MakePolygon(ST_ExteriorRing(dmp.geom), holes),
                                            ST_MakePolygon(ST_ExteriorRing(dmp.geom))
                                        ) gn

                             FROM ST_Dump(geometry) dmp, -- 1 dump polygons
                                  LATERAL (
                                      SELECT array_agg(ST_Boundary(rg.geom)) holes -- 2 create array
                                      FROM ST_DumpRings(dmp.geom) rg -- 3 from rings
                                      WHERE rg.path[1] > 0 -- 5 except inner ring
                                        AND ST_Area(rg.geom) >= power(zres12, 2) -- 4 bigger than
                                      ) holes
                         ) new_geom
                );
            END IF;

            IF ST_Area(geometry) < power(zres12, 2) THEN
                CONTINUE;
            END IF;

            -- simplify
            geometry := ST_SimplifyPreserveTopology(geometry, zres14::float);

            RETURN NEXT;
        END LOOP;
END;
$$ LANGUAGE plpgsql STABLE
                    STRICT
                    PARALLEL SAFE;


DROP MATERIALIZED VIEW IF EXISTS osm_building_block_gen1;

CREATE MATERIALIZED VIEW osm_building_block_gen1 AS
SELECT *
FROM osm_building_block_gen1();

CREATE INDEX ON osm_building_block_gen1 USING gist (geometry);
CREATE UNIQUE INDEX ON osm_building_block_gen1 USING btree (osm_id);


-- Handle updates

CREATE SCHEMA IF NOT EXISTS buildings;

CREATE TABLE IF NOT EXISTS buildings.updates
(
    id serial PRIMARY KEY,
    t text,
    UNIQUE (t)
);

CREATE OR REPLACE FUNCTION buildings.flag() RETURNS trigger AS
$$
BEGIN
    INSERT INTO buildings.updates(t) VALUES ('y') ON CONFLICT(t) DO NOTHING;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION buildings.refresh() RETURNS trigger AS
$$
DECLARE
    t TIMESTAMP WITH TIME ZONE := clock_timestamp();
BEGIN
    RAISE LOG 'Refresh buildings block';
    REFRESH MATERIALIZED VIEW osm_building_block_gen1;
    -- noinspection SqlWithoutWhere
    DELETE FROM buildings.updates;

    RAISE LOG 'Update buildings block done in %', age(clock_timestamp(), t);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_flag
    AFTER INSERT OR UPDATE OR DELETE
    ON osm_building_polygon
    FOR EACH STATEMENT
EXECUTE PROCEDURE buildings.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT
    ON buildings.updates
    INITIALLY DEFERRED
    FOR EACH ROW
EXECUTE PROCEDURE buildings.refresh();