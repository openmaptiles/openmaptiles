#!/bin/sh

# A script to run the "integrity" continuous integration script.

area=monaco
echo MIN_ZOOM=0 >> .env
echo MAX_ZOOM=14 >> .env
./quickstart.sh $area
export TEST_MODE=yes
make generate-devdoc
area=europe/monaco
echo DIFF_MODE=true >> .env

# Cleanup
rm -fr data build cache
# Create data/$area.repl.json
make download-geofabrik area=$area
# Download 2+ month old data
export old_date=$(date --date="$(date +%Y-%m-15) -2 month" +'%y%m01')
echo Downloading $old_date extract of $area
docker-compose run --rm --user=$(id -u):$(id -g) openmaptiles-tools sh -c "wget -O data/$area.osm.pbf http://download.geofabrik.de/$area-$old_date.osm.pbf"
# Initial import and tile generation
./quickstart.sh $area
sleep 2
echo Downloading updates
# Loop to recover from potential "ERROR 429: Too Many Requests"
docker-compose run --rm --user=$(id -u):$(id -g) openmaptiles-tools sh -c "
while ! osmupdate --keep-tempfiles --base-url=$(sed -n 's/ *\"replication_url\": //p' data/$area.repl.json) data/$area.osm.pbf data/changes.osc.gz ; do 
  sleep 2;
  echo Sleeping...;
  sleep 630;
done"
echo Downloading updates completed
echo Importing updates
make import-diff
echo Generating new tiles
make generate-tiles-pg
