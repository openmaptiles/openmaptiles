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
        ref,
		highway,
		z_order
	FROM (
		SELECT
			ST_LineMerge(ST_Union(geometry)) AS geometry,
			name,
            ref,
			highway,
			min(z_order) AS z_order,
			array_agg(DISTINCT osm_id) AS member_osm_ids
	    FROM osm_highway_linestring
        -- We only care about roads for labelling
	    WHERE name <> '' OR ref <> ''
	    GROUP BY name, highway, ref
	) AS highway_union
);

CREATE INDEX IF NOT EXISTS osm_highway_name_linestring_geometry_idx ON osm_highway_name_linestring USING gist(geometry);

CREATE TABLE IF NOT EXISTS osm_highway_name_linestring_gen1 AS (
    SELECT ST_Simplify(geometry, 50) AS geometry, osm_id, member_osm_ids, name, ref, highway, z_order
    FROM osm_highway_name_linestring
    WHERE highway IN ('motorway','trunk')  AND ST_Length(geometry) > 8000
);
CREATE INDEX IF NOT EXISTS osm_highway_name_linestring_gen1_geometry_idx ON osm_highway_name_linestring_gen1 USING gist(geometry);

CREATE TABLE IF NOT EXISTS osm_highway_name_linestring_gen2 AS (
    SELECT ST_Simplify(geometry, 120) AS geometry, osm_id, member_osm_ids, name, ref, highway, z_order
    FROM osm_highway_name_linestring_gen1
    WHERE highway IN ('motorway','trunk')  AND ST_Length(geometry) > 14000
);
CREATE INDEX IF NOT EXISTS osm_highway_name_linestring_gen2_geometry_idx ON osm_highway_name_linestring_gen2 USING gist(geometry);

CREATE TABLE IF NOT EXISTS osm_highway_name_linestring_gen3 AS (
    SELECT ST_Simplify(geometry, 120) AS geometry, osm_id, member_osm_ids, name, ref, highway, z_order
    FROM osm_highway_name_linestring_gen2
    WHERE highway = 'motorway' AND ST_Length(geometry) > 20000
);
CREATE INDEX IF NOT EXISTS osm_highway_name_linestring_gen3_geometry_idx ON osm_highway_name_linestring_gen3 USING gist(geometry);
