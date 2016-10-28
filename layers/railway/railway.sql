CREATE OR REPLACE FUNCTION railway_class(railway text, service text) RETURNS TEXT AS $$
    SELECT CASE
        WHEN railway='rail' AND service='' THEN 'rail'
        ELSE 'minor_rail'
    END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION railway_brunnel(is_bridge boolean, is_tunnel boolean) RETURNS TEXT AS $$
    SELECT CASE
         WHEN is_bridge THEN 'bridge'
         WHEN is_tunnel THEN 'tunnel'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION layer_railway(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text, subclass text, properties railway_properties) AS $$
    SELECT osm_id, geometry,
        railway_class(railway, service) AS class,
        railway AS subclass,
        to_railway_properties(is_bridge, is_tunnel) AS properties
    FROM (
        SELECT * FROM osm_railway_linestring
        WHERE zoom_level = 13 AND railway = 'rail' AND service=''
        UNION ALL
        SELECT * FROM osm_railway_linestring WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;
