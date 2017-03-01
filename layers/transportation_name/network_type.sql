DO $$
    BEGIN
        BEGIN
            ALTER TABLE osm_route_member ADD COLUMN network_type text;
        EXCEPTION
            WHEN duplicate_column THEN RAISE NOTICE 'column omt_type already exists in network_type.';
        END;
    END;
$$
;

-- see http://wiki.openstreetmap.org/wiki/Relation:route#Road_routes
UPDATE osm_route_member
SET network_type =
    CASE
      WHEN network = 'US:I' THEN 'us-interstate'
      WHEN network = 'US:US' THEN 'us-highway'
      WHEN network LIKE 'US:__' THEN 'us-state'
      ELSE ''
    END
;


DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'route_network_type') THEN
        CREATE TYPE route_network_type AS ENUM ('us-interstate', 'us-highway', 'us-state', '');
    END IF;
END
$$
;

ALTER TABLE osm_route_member ALTER COLUMN network_type TYPE route_network_type USING network_type::route_network_type;

-- select network_type, count(*)
-- from osm_route_member
-- WHERE network_type <> ''
-- group by network_type
-- order by network_type
-- ;
