#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "  Loading OMT postgis extensions"
echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

for db in template_postgis "$POSTGRES_DB"; do
echo "Loading extensions into $db"
PGUSER="$POSTGRES_USER" psql --dbname="$db" <<-'EOSQL'
    -- Cleanup. Ideally parent container shouldn't pre-install those.
    DROP EXTENSION IF EXISTS postgis_tiger_geocoder;
    DROP EXTENSION IF EXISTS postgis_topology;

    -- These extensions are already loaded by the parent docker
    CREATE EXTENSION IF NOT EXISTS postgis;
    CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;

    -- Extensions needed for OpenMapTiles
    CREATE EXTENSION IF NOT EXISTS hstore;
    CREATE EXTENSION IF NOT EXISTS unaccent;
    CREATE EXTENSION IF NOT EXISTS osml10n;
    CREATE EXTENSION IF NOT EXISTS gzip;
EOSQL
done
