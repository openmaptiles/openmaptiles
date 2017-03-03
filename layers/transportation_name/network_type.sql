DROP MATERIALIZED VIEW IF EXISTS osm_transportation_name_network CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_name_linestring CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_name_linestring_gen1 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_name_linestring_gen2 CASCADE;
DROP MATERIALIZED VIEW IF EXISTS osm_transportation_name_linestring_gen3 CASCADE;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'route_network_type') THEN
        CREATE TYPE route_network_type AS ENUM (
          'us-interstate', 'us-highway', 'us-state',
          'ca-transcanada'
        );
    END IF;
END
$$
;

DO $$
    BEGIN
        BEGIN
            ALTER TABLE osm_route_member ADD COLUMN network_type route_network_type;
        EXCEPTION
            WHEN duplicate_column THEN RAISE NOTICE 'column network_type already exists in network_type.';
        END;
    END;
$$
;

-- see http://wiki.openstreetmap.org/wiki/Relation:route#Road_routes
UPDATE osm_route_member
SET network_type =
    CASE
      WHEN network = 'US:I' THEN 'us-interstate'::route_network_type
      WHEN network = 'US:US' THEN 'us-highway'::route_network_type
      WHEN network LIKE 'US:__' THEN 'us-state'::route_network_type
      -- https://en.wikipedia.org/wiki/Trans-Canada_Highway
      -- TODO: improve hierarchical queries using
      --    http://www.openstreetmap.org/relation/1307243
      --    however the relation does not cover the whole Trans-Canada_Highway
      WHEN
          (network = 'CA:transcanada') OR
          (network = 'CA:BC:primary' AND ref IN ('16')) OR
          (name = 'Yellowhead Highway (AB)' AND ref IN ('16')) OR
          (network = 'CA:SK' AND ref IN ('16')) OR
          (network = 'CA:ON:primary' AND ref IN ('17', '417')) OR
          (name = 'Route Transcanadienne (QC)') OR
          (network = 'CA:NB' AND ref IN ('2', '16')) OR
          (network = 'CA:PEI' AND ref IN ('1')) OR
          (network = 'CA:NS' AND ref IN ('104', '105')) OR
          (network = 'CA:NL:R' AND ref IN ('1')) OR
          (name = '	Trans-Canada Highway (Super)')
        THEN 'ca-transcanada'::route_network_type
      ELSE NULL
    END
;
