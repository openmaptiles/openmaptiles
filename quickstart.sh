#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

DOCKER_EXEC=docker
DC_EXEC=docker-compose

#Check installed versions
echo "This requires a docker engine version 1.10.0+ and docker-compose 1.6.0+. If not, it is expected to fail. See https://docs.docker.com/engine/installation/ and https://docs.docker.com/compose/install/"
$DOCKER_EXEC --version
$DC_EXEC --version

#Remove 
$DC_EXEC down
$DC_EXEC rm -fv
echo "Remove old volume"
$DOCKER_EXEC volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true

echo "Make directories "
mkdir -p build
mkdir -p data

testdata=zurich_switzerland.osm.pbf
if [ !  -f ./data/${testdata} ]; then
    echo "Download $testdata   "
    rm -f ./data/*
    wget https://s3.amazonaws.com/metro-extracts.mapzen.com/zurich_switzerland.osm.pbf -P ./data
fi

$DOCKER_EXEC run --rm -v $(pwd):/tileset openmaptiles/openmaptiles-tools make
$DC_EXEC up   -d postgres
sleep 30

$DC_EXEC run --rm import-water
$DC_EXEC run --rm import-natural-earth
$DC_EXEC run --rm import-lakelines
$DC_EXEC run --rm import-osm
$DC_EXEC \
    BBOX="8.25,46.97,9.58,47.52" \
    MIN_ZOOM="0" \
    MAX_ZOOM="7" \
    run --rm import-sql

$DC_EXEC -f docker-compose.yml run --rm generate-vectortiles

$DC_EXEC stop postgres
echo "The vectortiles created from $testdata  "
ls ./data/*.mbtiles -la
echo "Hello ... start experimenting   - see docs !   "
