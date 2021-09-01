CREATE TABLE IF NOT EXISTS ne_10m_admin_0_bg_buffer AS
SELECT ST_Buffer(geometry, 10000)
FROM ne_10m_admin_0_countries
WHERE iso_a2 = 'GB';

CREATE OR REPLACE VIEW gbr_route_members_view AS
SELECT 0,
       osm_id,
       substring(ref FROM E'^[AM][0-9AM()]+'),
       CASE WHEN highway = 'motorway' THEN 'omt-gb-motorway' ELSE 'omt-gb-trunk' END
FROM osm_highway_linestring
WHERE length(ref) > 0
  AND ST_Intersects(geometry, (SELECT * FROM ne_10m_admin_0_bg_buffer))
  AND highway IN ('motorway', 'trunk')
;
-- Create GBR relations (so we can use it in the same way as other relations)
DELETE
FROM osm_route_member
WHERE network IN ('omt-gb-motorway', 'omt-gb-trunk');
-- etldoc:  osm_highway_linestring ->  osm_route_member
INSERT INTO osm_route_member (osm_id, member, ref, network)
SELECT *
FROM gbr_route_members_view;

CREATE OR REPLACE FUNCTION osm_route_member_network_type(network text) RETURNS route_network_type AS
$$
SELECT CASE
           WHEN network = 'US:I' THEN 'us-interstate'::route_network_type
           WHEN network = 'US:US' THEN 'us-highway'::route_network_type
           WHEN network LIKE 'US:__' THEN 'us-state'::route_network_type
           -- https://en.wikipedia.org/wiki/Trans-Canada_Highway
           WHEN network LIKE 'CA:transcanada%' THEN 'ca-transcanada'::route_network_type
           WHEN network = 'omt-gb-motorway' THEN 'gb-motorway'::route_network_type
           WHEN network = 'omt-gb-trunk' THEN 'gb-trunk'::route_network_type
           END;
$$ LANGUAGE sql IMMUTABLE
                PARALLEL SAFE;

-- etldoc:  osm_route_member ->  osm_route_member
-- see http://wiki.openstreetmap.org/wiki/Relation:route#Road_routes
UPDATE osm_route_member
SET network_type = osm_route_member_network_type(network)
WHERE network != ''
  AND network_type IS DISTINCT FROM osm_route_member_network_type(network)
;

CREATE OR REPLACE FUNCTION update_osm_route_member() RETURNS void AS
$$
BEGIN
    DELETE
    FROM osm_route_member AS r
        USING
            transportation_name.network_changes AS c
    WHERE network IN ('omt-gb-motorway', 'omt-gb-trunk')
      AND r.osm_id = c.osm_id;

    INSERT INTO osm_route_member (osm_id, member, ref, network)
    SELECT r.*
    FROM gbr_route_members_view AS r
             JOIN transportation_name.network_changes AS c ON
        r.osm_id = c.osm_id;

    UPDATE
        osm_route_member AS r
    SET network_type = osm_route_member_network_type(network)
    FROM transportation_name.network_changes AS c
    WHERE network != ''
      AND network_type IS DISTINCT FROM osm_route_member_network_type(network)
      AND r.member = c.osm_id;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX IF NOT EXISTS osm_route_member_network_idx ON osm_route_member ("network");
CREATE INDEX IF NOT EXISTS osm_route_member_member_idx ON osm_route_member ("member");
CREATE INDEX IF NOT EXISTS osm_route_member_name_idx ON osm_route_member ("name");
CREATE INDEX IF NOT EXISTS osm_route_member_ref_idx ON osm_route_member ("ref");

CREATE INDEX IF NOT EXISTS osm_route_member_network_type_idx ON osm_route_member ("network_type");

CREATE INDEX IF NOT EXISTS osm_highway_linestring_osm_id_idx ON osm_highway_linestring ("osm_id");
CREATE INDEX IF NOT EXISTS osm_highway_linestring_gen_z11_osm_id_idx ON osm_highway_linestring_gen_z11 ("osm_id");

ALTER TABLE osm_route_member ADD COLUMN IF NOT EXISTS concurrency_index int;

INSERT INTO osm_route_member (id, concurrency_index)
  SELECT
    id,
    ROW_NUMBER() over (PARTITION BY member ORDER BY network_type, network, LENGTH(ref), ref) AS concurrency_index
  FROM osm_route_member
  ON CONFLICT (id) DO UPDATE SET concurrency_index = EXCLUDED.concurrency_index;

UPDATE osm_highway_linestring hl
  SET network = rm.network_type
  FROM osm_route_member rm
  WHERE hl.osm_id=rm.member AND rm.concurrency_index=1;

UPDATE osm_highway_linestring_gen_z11 hl
  SET network = rm.network_type
  FROM osm_route_member rm
  WHERE hl.osm_id=rm.member AND rm.concurrency_index=1;
