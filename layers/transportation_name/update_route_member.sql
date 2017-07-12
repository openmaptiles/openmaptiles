DROP TRIGGER IF EXISTS trigger_flag_transportation_name ON osm_route_member;


-- create GBR relations (so we can use it in the same way as other relations)
CREATE OR REPLACE FUNCTION update_gbr_route_members() RETURNS VOID AS $$
DECLARE gbr_geom geometry;
BEGIN
  select st_buffer(geometry, 10000) into gbr_geom from ne_10m_admin_0_countries where iso_a2 = 'GB';
  delete from osm_route_member where network IN('omt-gb-motorway', 'omt-gb-trunk');

  insert into osm_route_member (member, ref, network)
    (
      SELECT hw.osm_id, substring(hw.ref from E'^[AM][0-9AM()]+'), 'omt-gb-motorway'
      from osm_highway_linestring hw
      where length(hw.ref)>0 and ST_Intersects(hw.geometry, gbr_geom)
        and hw.highway IN ('motorway')
    ) UNION (
      SELECT hw.osm_id, substring(hw.ref from E'^[AM][0-9AM()]+'), 'omt-gb-trunk'
      from osm_highway_linestring hw
      where length(hw.ref)>0 and ST_Intersects(hw.geometry, gbr_geom)
        and hw.highway IN ('trunk')
    )
  ;
END;
$$ LANGUAGE plpgsql;


-- etldoc:  osm_route_member ->  osm_route_member
CREATE OR REPLACE FUNCTION update_osm_route_member() RETURNS VOID AS $$
BEGIN
  PERFORM update_gbr_route_members();

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
        WHEN network = 'omt-gb-motorway' THEN 'gb-motorway'::route_network_type
        WHEN network = 'omt-gb-trunk' THEN 'gb-trunk'::route_network_type
        ELSE NULL
      END
  ;

END;
$$ LANGUAGE plpgsql;

CREATE INDEX IF NOT EXISTS osm_route_member_network_idx ON osm_route_member("network");
CREATE INDEX IF NOT EXISTS osm_route_member_member_idx ON osm_route_member("member");
CREATE INDEX IF NOT EXISTS osm_route_member_name_idx ON osm_route_member("name");
CREATE INDEX IF NOT EXISTS osm_route_member_ref_idx ON osm_route_member("ref");

SELECT update_osm_route_member();

CREATE INDEX IF NOT EXISTS osm_route_member_network_type_idx ON osm_route_member("network_type");
