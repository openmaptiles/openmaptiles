-- Create bounding windows for country-specific processing

-- etldoc: ne_10m_admin_0_countries ->  ne_10m_admin_0_gb_buffer
CREATE TABLE IF NOT EXISTS ne_10m_admin_0_gb_buffer AS
SELECT ST_Buffer(geometry, 10000)
FROM ne_10m_admin_0_countries
WHERE iso_a2 = 'GB';

-- etldoc: ne_10m_admin_0_countries ->  ne_10m_admin_0_ie_buffer
CREATE TABLE IF NOT EXISTS ne_10m_admin_0_ie_buffer AS
SELECT ST_Buffer(geometry, 10000)
FROM ne_10m_admin_0_countries
WHERE iso_a2 = 'IE';

-- Assign pseudo-networks based highway classification
-- etldoc:  osm_highway_linestring ->  gbr_route_members_view
-- etldoc:  ne_10m_admin_0_gb_buffer ->  gbr_route_members_view
CREATE OR REPLACE VIEW gbr_route_members_view AS
SELECT 0,
       osm_id,
       substring(ref FROM E'^[ABM][0-9ABM()]+'),
       -- See https://wiki.openstreetmap.org/wiki/Roads_in_the_United_Kingdom
       CASE WHEN highway = 'motorway' THEN 'omt-gb-motorway'
            WHEN highway = 'trunk' THEN 'omt-gb-trunk' 
            WHEN highway IN ('primary','secondary') THEN 'omt-gb-primary' END AS network
FROM osm_highway_linestring
WHERE length(ref) > 1
  AND ST_Intersects(geometry, (SELECT * FROM ne_10m_admin_0_gb_buffer))
  AND highway IN ('motorway', 'trunk', 'primary', 'secondary')
;

-- etldoc:  osm_highway_linestring ->  ire_route_members_view
-- etldoc:  ne_10m_admin_0_ie_buffer ->  ire_route_members_view
CREATE OR REPLACE VIEW ire_route_members_view AS
SELECT 0,
       osm_id,
       substring(ref FROM E'^[MNRL][0-9]+'),
       -- See https://wiki.openstreetmap.org/wiki/Ireland/Roads
       CASE WHEN highway = 'motorway' THEN 'omt-ie-motorway'
            WHEN highway IN ('trunk','primary') THEN 'omt-ie-national' 
            ELSE 'omt-ie-regional' END AS network
FROM osm_highway_linestring
WHERE length(ref) > 1
  AND ST_Intersects(geometry, (SELECT * FROM ne_10m_admin_0_ie_buffer))
  AND highway IN ('motorway', 'trunk', 'primary', 'secondary', 'unclassified')
;

-- Create GBR/IRE relations (so we can use it in the same way as other relations)
-- etldoc:  osm_route_member ->  osm_route_member
DELETE
FROM osm_route_member
WHERE network IN ('omt-gb-motorway', 'omt-gb-trunk', 'omt-gb-primary',
                  'omt-ie-motorway', 'omt-ie-national', 'omt-ie-national');

-- etldoc:  gbr_route_members_view ->  osm_route_member
INSERT INTO osm_route_member (osm_id, member, ref, network)
SELECT *
FROM gbr_route_members_view;

-- etldoc:  ire_route_members_view ->  osm_route_member
INSERT INTO osm_route_member (osm_id, member, ref, network)
SELECT *
FROM ire_route_members_view;

CREATE OR REPLACE FUNCTION osm_route_member_network_type(network text, ref text) RETURNS route_network_type AS
$$
SELECT CASE
           WHEN network = 'US:I' THEN 'us-interstate'::route_network_type
           WHEN network = 'US:US' THEN 'us-highway'::route_network_type
           WHEN network LIKE 'US:__' THEN 'us-state'::route_network_type
           -- https://en.wikipedia.org/wiki/Trans-Canada_Highway
           WHEN network LIKE 'CA:transcanada%' THEN 'ca-transcanada'::route_network_type
           WHEN network = 'CA:QC:A' THEN 'ca-provincial-arterial'::route_network_type
           WHEN network = 'CA:ON:primary' THEN
               CASE
                   WHEN ref LIKE '4__' THEN 'ca-provincial-arterial'::route_network_type
                   WHEN ref = 'QEW' THEN 'ca-provincial-arterial'::route_network_type
                   ELSE 'ca-provincial-arterial'::route_network_type
               END
           WHEN network = 'CA:MB:PTH' AND ref = '75' THEN 'ca-provincial-arterial'::route_network_type
           WHEN network = 'CA:AB:primary' AND ref IN ('2','3','4') THEN 'ca-provincial-arterial'::route_network_type
           WHEN network = 'CA:BC' AND ref IN ('3','5','99') THEN 'ca-provincial-arterial'::route_network_type
           WHEN network LIKE 'CA:__' OR network LIKE 'CA:__:%' THEN 'ca-provincial'::route_network_type
           WHEN network = 'omt-gb-motorway' THEN 'gb-motorway'::route_network_type
           WHEN network = 'omt-gb-trunk' THEN 'gb-trunk'::route_network_type
           WHEN network = 'omt-gb-primary' THEN 'gb-primary'::route_network_type
           WHEN network = 'omt-ie-motorway' THEN 'ie-motorway'::route_network_type
           WHEN network = 'omt-ie-national' THEN 'ie-national'::route_network_type
           WHEN network = 'omt-ie-regional' THEN 'ie-regional'::route_network_type
            END;
$$ LANGUAGE sql IMMUTABLE
                PARALLEL SAFE;

-- etldoc:  osm_route_member ->  osm_route_member
-- see http://wiki.openstreetmap.org/wiki/Relation:route#Road_routes
UPDATE osm_route_member
SET network_type = osm_route_member_network_type(network, ref)
WHERE network != ''
  AND network_type IS DISTINCT FROM osm_route_member_network_type(network, ref)
;

CREATE OR REPLACE FUNCTION update_osm_route_member() RETURNS void AS
$$
BEGIN
    DELETE
    FROM osm_route_member AS r
        USING
            transportation_name.network_changes AS c
    WHERE network IN ('omt-gb-motorway', 'omt-gb-trunk', 'omt-gb-primary',
                      'omt-ie-motorway', 'omt-ie-national', 'omt-ie-regional')
      AND r.osm_id = c.osm_id;

    INSERT INTO osm_route_member (osm_id, member, ref, network)
    SELECT r.*
    FROM gbr_route_members_view AS r
             JOIN transportation_name.network_changes AS c ON
        r.osm_id = c.osm_id;

    INSERT INTO osm_route_member (osm_id, member, ref, network)
    SELECT r.*
    FROM ire_route_members_view AS r
             JOIN transportation_name.network_changes AS c ON
        r.osm_id = c.osm_id;

    INSERT INTO osm_route_member (id, osm_id, network_type, concurrency_index, rank)
    SELECT
      id,
      osm_id,
      osm_route_member_network_type(network, ref) AS network_type,
      DENSE_RANK() over (PARTITION BY member ORDER BY network_type, network, LENGTH(ref), ref) AS concurrency_index,
      CASE
           WHEN network IN ('iwn', 'nwn', 'rwn') THEN 1
           WHEN network = 'lwn' THEN 2
           WHEN osmc_symbol || colour <> '' THEN 2
      END AS rank
    FROM osm_route_member rm
    WHERE rm.member IN
      (SELECT DISTINCT osm_id FROM transportation_name.network_changes)
    ON CONFLICT (id, osm_id) DO UPDATE SET concurrency_index = EXCLUDED.concurrency_index,
                                           rank = EXCLUDED.rank,
                                           network_type = EXCLUDED.network_type;
END;
$$ LANGUAGE plpgsql;

CREATE INDEX IF NOT EXISTS osm_route_member_network_idx ON osm_route_member ("network", "ref");
CREATE INDEX IF NOT EXISTS osm_route_member_member_idx ON osm_route_member ("member");
CREATE INDEX IF NOT EXISTS osm_route_member_name_idx ON osm_route_member ("name");
CREATE INDEX IF NOT EXISTS osm_route_member_ref_idx ON osm_route_member ("ref");

CREATE INDEX IF NOT EXISTS osm_route_member_network_type_idx ON osm_route_member ("network_type");

/**
* Discard duplicate routes
*/
DELETE FROM osm_route_member WHERE id IN
   (SELECT id
    FROM (SELECT id,
                 ROW_NUMBER() OVER (partition BY member, network, ref ORDER BY id) AS rnum
          FROM osm_route_member) t
    WHERE t.rnum > 1);
CREATE UNIQUE INDEX IF NOT EXISTS osm_route_member_network_ref_idx ON osm_route_member ("member", "network", "ref");

CREATE INDEX IF NOT EXISTS osm_highway_linestring_osm_id_idx ON osm_highway_linestring ("osm_id");
CREATE UNIQUE INDEX IF NOT EXISTS osm_highway_linestring_gen_z11_osm_id_idx ON osm_highway_linestring_gen_z11 ("osm_id");

ALTER TABLE osm_route_member ADD COLUMN IF NOT EXISTS concurrency_index int,
                             ADD COLUMN IF NOT EXISTS rank int;

-- One-time load of concurrency indexes; updates occur via trigger
-- etldoc:  osm_route_member ->  osm_route_member
INSERT INTO osm_route_member (id, osm_id, concurrency_index, rank)
  SELECT
    id,
    osm_id,
    DENSE_RANK() over (PARTITION BY member ORDER BY network_type, network, LENGTH(ref), ref) AS concurrency_index,
    CASE
         WHEN network IN ('iwn', 'nwn', 'rwn') THEN 1
         WHEN network = 'lwn' THEN 2
         WHEN osmc_symbol || colour <> '' THEN 2
    END AS rank
  FROM osm_route_member
  ON CONFLICT (id, osm_id) DO UPDATE SET concurrency_index = EXCLUDED.concurrency_index, rank = EXCLUDED.rank;

-- etldoc:  osm_route_member ->  osm_highway_linestring
UPDATE osm_highway_linestring hl
  SET network = rm.network_type
  FROM osm_route_member rm
  WHERE hl.osm_id=rm.member AND rm.concurrency_index=1;

-- etldoc:  osm_route_member ->  osm_highway_linestring_gen_z11
UPDATE osm_highway_linestring_gen_z11 hl
  SET network = rm.network_type
  FROM osm_route_member rm
  WHERE hl.osm_id=rm.member AND rm.concurrency_index=1;
