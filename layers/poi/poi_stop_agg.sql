-- etldoc:  osm_poi_point ->  osm_poi_stop_centroid
DROP MATERIALIZED VIEW IF EXISTS osm_poi_stop_centroid CASCADE;
CREATE MATERIALIZED VIEW osm_poi_stop_centroid AS
(
SELECT uic_ref,
       count(*) AS count,
       CASE WHEN count(*) > 2 THEN ST_Centroid(ST_UNION(geometry)) END AS centroid
FROM osm_poi_point
WHERE uic_ref <> ''
  AND subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
GROUP BY uic_ref
HAVING count(*) > 1
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;

-- etldoc:  osm_poi_stop_centroid ->  osm_poi_stop_rank
-- etldoc:  osm_poi_point ->  osm_poi_stop_rank
DROP MATERIALIZED VIEW IF EXISTS osm_poi_stop_rank CASCADE;
CREATE MATERIALIZED VIEW osm_poi_stop_rank AS
(
SELECT p.osm_id,
-- 		p.uic_ref,
-- 		p.subclass,
       ROW_NUMBER()
       OVER (
           PARTITION BY p.uic_ref
           ORDER BY
               p.subclass :: public_transport_stop_type NULLS LAST,
               ST_Distance(c.centroid, p.geometry)
           ) AS rk
FROM osm_poi_point p
         INNER JOIN osm_poi_stop_centroid c ON (p.uic_ref = c.uic_ref)
WHERE subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
ORDER BY p.uic_ref, rk
    ) /* DELAY_MATERIALIZED_VIEW_CREATION */;
