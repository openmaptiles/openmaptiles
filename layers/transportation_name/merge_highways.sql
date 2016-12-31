
-- Instead of using relations to find out the road names we
-- stitch together the touching ways with the same name
-- to allow for nice label rendering
-- Because this works well for roads that do not have relations as well

-- etldoc: osm_highway_linestring ->  osm_transportation_name_linestring
CREATE OR REPLACE FUNCTION osm_transportation_name_linestring(bbox geometry, zoom_level int)
    RETURNS TABLE(geometry geometry, osm_id bigint, member_osm_ids bigint[], name varchar, ref varchar, highway varchar, z_order int) AS $$
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
        -- We only care about highways (not railways) for labeling
	    WHERE (name <> '' OR ref <> '') AND NULLIF(highway, '') IS NOT NULL AND geometry && bbox
	    GROUP BY name, highway, ref
	) AS highway_union;
$$ LANGUAGE SQL IMMUTABLE;

-- etldoc: osm_transportation_name_linestring -> osm_transportation_name_linestring_gen1
CREATE OR REPLACE FUNCTION osm_transportation_name_linestring_gen1(bbox geometry, zoom_level int)
    RETURNS TABLE(geometry geometry, osm_id bigint, member_osm_ids bigint[], name varchar, ref varchar, highway varchar, z_order int) AS $$
    SELECT ST_Simplify(geometry, 50) AS geometry, osm_id, member_osm_ids, name, ref, highway, z_order
    FROM osm_transportation_name_linestring
    WHERE highway IN ('motorway','trunk')  AND ST_Length(geometry) > 8000 AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

-- etldoc: osm_transportation_name_linestring_gen1 -> osm_transportation_name_linestring_gen2
CREATE OR REPLACE FUNCTION osm_transportation_name_linestring_gen2(bbox geometry, zoom_level int)
    RETURNS TABLE(geometry geometry, osm_id bigint, member_osm_ids bigint[], name varchar, ref varchar, highway varchar, z_order int) AS $$
    SELECT ST_Simplify(geometry, 120) AS geometry, osm_id, member_osm_ids, name, ref, highway, z_order
    FROM osm_transportation_name_linestring_gen1(bbox, zoom_level)
    WHERE highway IN ('motorway','trunk')  AND ST_Length(geometry) > 14000 AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

-- etldoc: osm_transportation_name_linestring_gen2 -> osm_transportation_name_linestring_gen3
CREATE OR REPLACE FUNCTION osm_transportation_name_linestring_gen3(bbox geometry, zoom_level int)
    RETURNS TABLE(geometry geometry, osm_id bigint, member_osm_ids bigint[], name varchar, ref varchar, highway varchar, z_order int) AS $$
    SELECT ST_Simplify(geometry, 120) AS geometry, osm_id, member_osm_ids, name, ref, highway, z_order
    FROM osm_transportation_name_linestring_gen2(bbox, zoom_level)
    WHERE highway = 'motorway' AND ST_Length(geometry) > 20000 AND geometry && bbox;
$$ LANGUAGE SQL IMMUTABLE;

