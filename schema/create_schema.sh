#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

function exec_psql_file() {
    local file_name="$1"
    PGPASSWORD="$POSTGRES_PASSWORD" psql \
        -v ON_ERROR_STOP="1" \
        --host="$POSTGRES_HOST" \
        --port="$POSTGRES_PORT" \
        --dbname="$POSTGRES_DB" \
        --username="$POSTGRES_USER" \
        -f "$file_name"
}

function main() {
    exec_psql_file "$VT_UTIL_DIR/postgis-vt-util.sql"
    exec_psql_file "layers/water.sql"
    exec_psql_file "layers/building.sql"
}

main
