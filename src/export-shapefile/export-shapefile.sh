#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

function export_shp() {
    local lake_shapefile="/data/osm_lake_polygon.shp"
    local query="SELECT osm_id, name, name_en, ST_SimplifyPreserveTopology(geometry, 100) AS geometry FROM osm_water_polygon WHERE area > 2 * 1000 * 1000 AND ST_GeometryType(geometry)='ST_Polygon' AND name <> '' ORDER BY area DESC"
    pgsql2shp -f "$lake_shapefile" \
        -h "$PGHOST" \
        -u "$PGUSER" \
        -P "$PGPASSWORD" \
        "$PGDATABASE" "$query"
}

export_shp
