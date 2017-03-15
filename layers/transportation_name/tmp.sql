select ref, highway, network,
    case
      when network is not null
        then network::text
      when length(coalesce(ref, ''))>0
        then 'motorway'
    end as shield
from osm_transportation_name_linestring;



SELECT
    rm.network,
    rm.ref::text as network_ref,
    hl.ref as road_ref,
    hl.highway,
    ROW_NUMBER() OVER(PARTITION BY hl.osm_id
                                 ORDER BY rm.network) AS "rank"
FROM osm_highway_linestring hl
left join osm_route_member rm on (rm.member = hl.osm_id)
;

select network, count(*)
from osm_route_member
group by network;

select network, ref, count(*)
from osm_route_member
group by network, ref
order by network, ref;

select *
from osm_route_member
where ref::int < 3;


select ref, network, name, count(*)
from osm_route_member
where name like '%Trans-Canada Highway%'
group by ref, network, name;


select ref, count(*)
from osm_highway_linestring
group by (ref)
order by count(*) desc;

select ref, highway, count(*)
from osm_highway_linestring
where length(ref)>0
and ref like 'A%' or ref like 'M%'
group by ref, highway
order by count(*) desc;

select ref, count(*)
from osm_highway_linestring
where length(ref)>0
and ref like 'A%' or ref like 'M%'
group by ref
order by count(*) desc;


select ref, count(*)
from osm_highway_linestring
where length(ref)>0
and highway = 'motorway'
group by ref
order by count(*) desc;

select count(hw.*)
from osm_highway_linestring hw CROSS JOIN ne_10m_admin_0_countries c
where c.iso_a2 = 'GB'
AND ST_Intersects(hw.geometry, c.geometry);

select hw.osm_id, hw.name, hw.ref
from osm_highway_linestring hw CROSS JOIN ne_10m_admin_0_countries c
where c.iso_a2 = 'GB'
AND not ST_Intersects(hw.geometry, c.geometry);



select count(*)
from osm_highway_linestring;


select * from ne_10m_admin_0_countries;
select name, ST_GeometryType(geometry) from ne_10m_admin_0_countries where iso_a2 = 'GB';
select geometry from ne_10m_admin_0_countries where iso_a2 = 'GB';


with gb_geom as (select geometry from ne_10m_admin_0_countries where iso_a2 = 'GB')
  select hw.osm_id, hw.name, hw.ref
  from osm_highway_linestring hw
  where not ST_Intersects(hw.geometry, gb_geom);


DO $$
DECLARE gbr_geom geometry;
BEGIN
  select geometry into gbr_geom from ne_10m_admin_0_countries where iso_a2 = 'GB';
  select hw.osm_id, hw.name, hw.ref
  from osm_highway_linestring hw
  where not ST_Intersects(hw.geometry, gbr_geom);
  -- ...
END $$;


DO $$
DECLARE gbr_geom geometry;
BEGIN
  select st_buffer(geometry, 1000) into gbr_geom from ne_10m_admin_0_countries where iso_a2 = 'GB';
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
      where length(hw.ref)>0
        and hw.highway IN ('trunk')
    )
  ;
END $$;


SELECT hw.osm_id, hw.ref, substring(hw.ref from E'^[AM][0-9AM()]+'), 'omt-gb-motorway'
from osm_highway_linestring hw
where length(hw.ref)>0
  and hw.highway IN ('motorway');

  SELECT hw.osm_id, hw.ref, substring(hw.ref from E'^[AM][0-9AM()]+'), 'omt-gb-trunk'
  from osm_highway_linestring hw
  where length(hw.ref)>0
    and hw.highway IN ('trunk');
