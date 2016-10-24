CREATE OR REPLACE FUNCTION railway_class(railway text, service text) RETURNS TEXT AS $$
    SELECT CASE
        WHEN railway='rail' AND service='' THEN 'rail'
        ELSE 'minor'
    END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION railway_brunnel(is_bridge boolean, is_tunnel boolean) RETURNS TEXT AS $$
    SELECT CASE
         WHEN is_bridge THEN 'bridge'
         WHEN is_tunnel THEN 'tunnel'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE VIEW railway_z13 AS (
    SELECT * FROM osm_railway_linestring
    WHERE railway = 'rail' AND service=''
);

CREATE OR REPLACE VIEW railway_z14 AS (
    SELECT * FROM osm_railway_linestring
);

CREATE OR REPLACE FUNCTION layer_railway(bbox geometry, zoom_level int)
RETURNS TABLE(osm_id bigint, geometry geometry, class text, subclass text, brunnel text) AS $$
    SELECT osm_id, geometry,
        railway_class(railway, service) AS class,
        railway AS subclass,
        railway_brunnel(is_bridge, is_tunnel) AS brunnel
    FROM (
        SELECT * FROM railway_z13 WHERE zoom_level = 13
        UNION ALL
        SELECT * FROM railway_z14 WHERE zoom_level >= 14
    ) AS zoom_levels
    WHERE geometry && bbox
    ORDER BY z_order ASC;
$$ LANGUAGE SQL IMMUTABLE;
