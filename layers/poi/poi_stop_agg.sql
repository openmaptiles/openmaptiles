DROP MATERIALIZED VIEW IF EXISTS osm_poi_stop_centroid CASCADE;
CREATE MATERIALIZED VIEW osm_poi_stop_centroid AS (
  SELECT
      uic_ref,
      count(*) as count,
			CASE WHEN count(*) > 2 THEN ST_Centroid(ST_UNION(geometry))
			ELSE NULL END AS centroid
  FROM osm_poi_point
	WHERE
		nullif(uic_ref, '') IS NOT NULL
		AND subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
	GROUP BY
		uic_ref
	HAVING
		count(*) > 1
);

DROP MATERIALIZED VIEW IF EXISTS osm_poi_stop_rank CASCADE;
CREATE MATERIALIZED VIEW osm_poi_stop_rank AS (
	SELECT
		p.osm_id,
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
	WHERE
		subclass IN ('bus_stop', 'bus_station', 'tram_stop', 'subway')
	ORDER BY p.uic_ref, rk
);

ALTER TABLE osm_poi_point ADD COLUMN IF NOT EXISTS agg_stop INTEGER DEFAULT NULL;
SELECT update_osm_poi_point_agg();