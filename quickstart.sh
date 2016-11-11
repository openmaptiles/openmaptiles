#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

#Check installed versions
docker --version
docker-compose --version

#Remove 
docker-compose down
docker-compose rm -fv
echo "Remove old volume"
docker volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true

echo "Make directories "
mkdir -p build
mkdir -p data

testdata=zurich_switzerland.osm.pbf
if [ !  -f ./data/${testdata} ]; then
    echo "Download $testdata   "
    rm -f ./data/*
    wget https://s3.amazonaws.com/metro-extracts.mapzen.com/zurich_switzerland.osm.pbf -P ./data
fi


docker run --rm -v $(pwd):/tileset openmaptiles/openmaptiles-tools make
docker-compose up   -d postgres
sleep 30

docker-compose run --rm import-water
docker-compose run --rm import-natural-earth
docker-compose run --rm import-lakelines
docker-compose run --rm import-osm
docker-compose run --rm import-sql

docker-compose -f docker-compose.yml -f docker-compose-test-override.yml  run --rm generate-vectortiles

docker-compose stop postgres
echo "The vectortiles created from $testdata  "
ls ./data/*.mbtiles -la
echo "Hello ... start experimenting   - see docs !   "



