-- Instead of using relations to find out the road names we
-- stitch together the touching ways with the same name
-- to allow for nice label rendering
-- Because this works well for roads that do not have relations as well
CREATE TABLE IF NOT EXISTS osm_highway_name_linestring AS (
	SELECT
		(ST_Dump(geometry)).geom AS geometry,
        -- NOTE: The osm_id is no longer the original one which can make it difficult
        -- to lookup road names by OSM ID
		member_osm_ids[0] AS osm_id,
		member_osm_ids,
		name,
		highway,
		z_order
	FROM (
		SELECT
			ST_LineMerge(ST_Union(geometry)) AS geometry,
			name,
			highway,
			min(z_order) AS z_order,
			array_agg(DISTINCT osm_id) AS member_osm_ids
	    FROM osm_highway_linestring
        -- We only care about roads for labelling
	    WHERE name <> ''
	    GROUP BY name, highway
	) AS highway_union
);

CREATE INDEX IF NOT EXISTS osm_highway_name_linestring_geometry_idx ON osm_important_place_point USING gist(geometry);
