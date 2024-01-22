DROP TRIGGER IF EXISTS trigger_store_transportation_highway_linestring ON osm_highway_linestring;

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
SELECT osm_id AS member,
       substring(ref FROM E'^[ABM][0-9ABM()]+') AS ref,
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
SELECT osm_id AS member,
       substring(ref FROM E'^[MNRL][0-9]+') AS ref,
       -- See https://wiki.openstreetmap.org/wiki/Ireland/Roads
       CASE WHEN highway = 'motorway' THEN 'omt-ie-motorway'
            WHEN highway IN ('trunk','primary') THEN 'omt-ie-national'
            ELSE 'omt-ie-regional' END AS network
FROM osm_highway_linestring
WHERE length(ref) > 1
  AND ST_Intersects(geometry, (SELECT * FROM ne_10m_admin_0_ie_buffer))
  AND highway IN ('motorway', 'trunk', 'primary', 'secondary', 'unclassified')
;

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
                   ELSE 'ca-provincial'::route_network_type
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

CREATE TABLE IF NOT EXISTS transportation_route_member_coalesced
(
    member            bigint,
    network           varchar,
    ref               varchar,
    osm_id            bigint not null,
    role              varchar,
    type              smallint,
    name              varchar,
    osmc_symbol       varchar,
    colour            varchar,
    network_type      route_network_type,
    concurrency_index integer,
    rank              integer,
    PRIMARY KEY (member, network, ref)
);

CREATE OR REPLACE FUNCTION update_osm_route_member(full_update bool) RETURNS void AS
$$
BEGIN
    -- Analyze tracking and source tables before performing update
    ANALYZE transportation_name.network_changes;
    ANALYZE osm_highway_linestring;
    ANALYZE osm_route_member;

    DELETE
    FROM transportation_route_member_coalesced
    USING transportation_name.network_changes c
    WHERE c.is_old IS TRUE AND transportation_route_member_coalesced.member = c.osm_id;

    -- Create GBR/IRE relations (so we can use it in the same way as other relations)
    -- etldoc:  gbr_route_members_view ->  transportation_route_member_coalesced
    INSERT INTO transportation_route_member_coalesced (member, network, ref, network_type, concurrency_index, osm_id)
    SELECT member, network, coalesce(ref, '') AS ref,
           osm_route_member_network_type(network, coalesce(ref, '')) AS network_type,
           1 AS concurrency_index, 0 AS osm_id
    FROM gbr_route_members_view
    WHERE full_update OR EXISTS(
        SELECT NULL
        FROM transportation_name.network_changes c
        WHERE c.is_old IS FALSE AND c.osm_id = gbr_route_members_view.member
    )
    GROUP BY member, network, coalesce(ref, '')
    ON CONFLICT (member, network, ref) DO NOTHING;

    -- etldoc:  ire_route_members_view ->  transportation_route_member_coalesced
    INSERT INTO transportation_route_member_coalesced (member, network, ref, network_type, concurrency_index, osm_id)
    SELECT member, network, coalesce(ref, '') AS ref,
           osm_route_member_network_type(network, coalesce(ref, '')) AS network_type,
           1 AS concurrency_index, 0 AS osm_id
    FROM ire_route_members_view
    WHERE full_update OR EXISTS(
        SELECT NULL
        FROM transportation_name.network_changes c
        WHERE c.is_old IS FALSE AND c.osm_id = ire_route_members_view.member
    )
    GROUP BY member, network, coalesce(ref, '')
    ON CONFLICT (member, network, ref) DO NOTHING;

    -- etldoc: osm_route_member ->  transportation_route_member_coalesced
    INSERT INTO transportation_route_member_coalesced
    SELECT
      osm_route_member_filtered.*,
      osm_route_member_network_type(network, ref) AS network_type,
      DENSE_RANK() OVER (
          PARTITION BY member
          ORDER BY osm_route_member_network_type(network, ref), network, LENGTH(ref), ref
      ) AS concurrency_index,
      CASE
           WHEN network IN ('iwn', 'nwn', 'rwn') THEN 1
           WHEN network = 'lwn' THEN 2
           WHEN osmc_symbol || colour <> '' THEN 2
      END AS rank
    FROM (
        -- etldoc:  osm_route_member ->  osm_route_member
        -- see http://wiki.openstreetmap.org/wiki/Relation:route#Road_routes
        SELECT DISTINCT ON (member, COALESCE(network, ''), COALESCE(ref, ''))
            member,
            COALESCE(network, '') AS network,
            COALESCE(ref, '') AS ref,
            osm_id,
            role,
            type,
            name,
            osmc_symbol,
            colour
        FROM osm_route_member
        WHERE full_update OR EXISTS(
            SELECT NULL
            FROM transportation_name.network_changes c
            WHERE c.is_old IS FALSE AND c.osm_id = osm_route_member.member
        )
    ) osm_route_member_filtered
    ON CONFLICT (member, network, ref) DO UPDATE SET osm_id = EXCLUDED.osm_id, role = EXCLUDED.role,
                                                     type = EXCLUDED.type, name = EXCLUDED.name,
                                                     osmc_symbol = EXCLUDED.osmc_symbol, colour = EXCLUDED.colour,
                                                     concurrency_index = EXCLUDED.concurrency_index,
                                                     rank = EXCLUDED.rank;
END;
$$ LANGUAGE plpgsql;

-- Indexes which can be utilized during full-update for queries originating from update_osm_route_member() function
CREATE INDEX IF NOT EXISTS osm_route_member_member_network_ref_idx
    ON osm_route_member (member, COALESCE(network, ''), COALESCE(ref, ''));

-- Analyze created index
ANALYZE osm_route_member;

-- Ensure transportation_name.network_changes table exists since it is required by update_osm_route_member
CREATE SCHEMA IF NOT EXISTS transportation_name;
CREATE TABLE IF NOT EXISTS transportation_name.network_changes
(
    is_old bool,
    osm_id bigint,
    PRIMARY KEY (is_old, osm_id)
);

-- Fill transportation_route_member_coalesced table
TRUNCATE transportation_route_member_coalesced;
SELECT update_osm_route_member(TRUE);

-- Index for queries against transportation_route_member_coalesced during transportation-name-network updates
CREATE INDEX IF NOT EXISTS transportation_route_member_member_idx ON
    transportation_route_member_coalesced ("member", "concurrency_index");

-- Analyze populated table with indexes
ANALYZE transportation_route_member_coalesced;

-- Ensure OSM-ID index exists on osm_highway_linestring
CREATE UNIQUE INDEX IF NOT EXISTS osm_highway_linestring_osm_id_idx ON osm_highway_linestring ("osm_id");

-- etldoc:  osm_route_member ->  osm_highway_linestring
UPDATE osm_highway_linestring hl
  SET network = rm.network_type
  FROM transportation_route_member_coalesced rm
  WHERE hl.osm_id=rm.member AND rm.concurrency_index=1;

-- etldoc:  osm_route_member ->  osm_highway_linestring_gen_z11
UPDATE osm_highway_linestring_gen_z11 hl
  SET network = rm.network_type
  FROM transportation_route_member_coalesced rm
  WHERE hl.osm_id=rm.member AND rm.concurrency_index=1;
