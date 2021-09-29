DROP TABLE IF EXISTS osm_border_linestring_adm CASCADE;

-- etldoc: osm_border_linestring -> osm_border_linestring_adm
-- etldoc: osm_border_disp_linestring -> osm_border_linestring_adm
-- etldoc: ne_10m_admin_0_countries -> osm_border_linestring_adm
CREATE TABLE IF NOT EXISTS osm_border_linestring_adm AS ( 
  WITH 
    -- Prepare lines from osm to be merged
	multiline AS (
        SELECT osm_id,
               ST_Node(ST_Collect(geometry)) AS geometry,
               BOOL_OR(maritime) AS maritime,
               FALSE AS disputed
    	FROM osm_border_linestring
    	WHERE admin_level = 2 AND ST_Dimension(geometry) = 1
		    AND osm_id NOT IN (SELECT DISTINCT osm_id FROM osm_border_disp_linestring)
              GROUP BY osm_id
		),

	mergedline AS (
		SELECT osm_id,
      		     (ST_Dump(ST_LineMerge(geometry))).geom AS geometry,
			maritime,
			disputed
  		FROM multiline
		),
    -- Create polygons from all boundaries to preserve real shape of country
	polyg AS (
    	SELECT (ST_Dump(
        		 ST_Polygonize(geometry))).geom AS geometry  
    	FROM (
			SELECT (ST_Dump(
      				ST_LineMerge(geometry))).geom AS geometry
  			FROM (SELECT ST_Node(
                          ST_Collect(geometry)) AS geometry
    			FROM osm_border_linestring
    			WHERE admin_level = 2 AND ST_Dimension(geometry) = 1
                ) nodes
			) linemerge
  		), 

    centroids AS (
		SELECT polyg.geometry,
			   ne.adm0_a3
		FROM polyg,
			 ne_10m_admin_0_countries AS ne
		WHERE ST_Within(
			   ST_PointOnSurface(polyg.geometry), ne.geometry)
    	),

	country_osm_polyg AS  (
		SELECT country.adm0_a3,
			   border.geometry
  		FROM polyg border,
			 centroids country
  		WHERE ST_Within(country.geometry, border.geometry)
	),

	rights AS (
        SELECT osm_id,
			   adm0_r,
			   geometry,
			   maritime,
			   disputed
		FROM (
			SELECT a.osm_id AS osm_id,
                   b.adm0_a3 AS adm0_r,
                   a.geometry,
                   a.maritime,
                   a.disputed
			FROM mergedline AS a
			LEFT JOIN country_osm_polyg AS b
            -- Create short line on the right of the boundary (mergedline) and find state where line lies.
			ON ST_Within(
				ST_OffsetCurve(
				(ST_LineSubString(a.geometry, 0.3,0.3004)), 70, 'quad_segs=4 join=mitre'), b.geometry)
            ) line_rights
		)

  SELECT osm_id,
		 adm0_l,
		 adm0_r,
		 geometry,
		 maritime,
		 2::integer AS admin_level,
		 disputed
  FROM (
    SELECT r.osm_id AS osm_id,
           b.adm0_a3 AS adm0_l,
           r.adm0_r AS adm0_r,
           r.geometry,
           r.maritime,
           r.disputed
    FROM rights AS r
    LEFT JOIN country_osm_polyg AS b
      -- Create short line on the left of the boundary (mergedline) and find state where line lies.
      ON ST_Within(
        ST_OffsetCurve(
          (ST_LineSubString(r.geometry, 0.4,0.4004)), -70, 'quad_segs=4 join=mitre'), b.geometry)
    ) both_lines
);

CREATE INDEX IF NOT EXISTS osm_border_linestring_adm_geom_idx
  ON osm_border_linestring_adm
  USING GIST (geometry);
