#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

##
##  OpenMapTiles quickstart.sh 
##  

STARTTIME=$(date +%s)
STARTDATE=$(date -Iminutes)
githash=$( git rev-parse HEAD )

log_file=quickstart.log
rm -f $log_file
exec &> >(tee -a "$log_file")

echo "====> : OpenMapTiles quickstart! [ https://github.com/openmaptiles/openmaptiles ] "
echo "      : This will be logged to the $log_file file ( for debugging) and to the screen"
echo "      : git version: $githash  / started: $STARTDATE "
echo "      : Your system is:"
lsb_release -a

echo "====> : Please check the docker and docker-compose version!"
echo "      : We are using docker-compose V2 file format !  see more: https://docs.docker.com/ "
echo "      : (theoretically;not tested) minumum Docker version is 1.10.0+. "
echo "      : (theoretically;not tested) minimum Docker-compose version is 1.6.0+."
echo "      : See the .travis testfile for the current supported versions "
echo "      : Your docker systems is:"
docker         --version
docker-compose --version

echo "====> : Checking OpenMapTiles docker images "
docker images | grep openmaptiles

echo "====> : Stop running services & Removing old containers "
docker-compose down
docker-compose rm -fv

echo "====> : For a clean start, We are removing old postgresql data volume ( if exists )"
docker volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true

echo "====> : Making directories - if not exists (./build ./data ) "
mkdir -p build
mkdir -p data

echo "====> : Removing old MBTILES if exists ( ./data/*.mbtiles ) "
rm -f ./data/*.mbtiles

testdata=zurich_switzerland.osm.pbf
testdataurl=https://s3.amazonaws.com/metro-extracts.mapzen.com/$testdata
if [ !  -f ./data/${testdata} ]; then
    echo "====> : The testdata downloading $testdata   "
    rm -f ./data/*
    wget $testdataurl  -P ./data
else
    echo "====> : The testdata ./data/$testdata exists, we don't download! "    
fi

echo " "
echo "====> : Clean old generated source files ( ./build/* ) ( if exists ) "
docker run --rm -v $(pwd):/tileset openmaptiles/openmaptiles-tools make clean_build

echo " "
echo "====> : Code generating from the layer definitions ( ./build/mapping.yaml; ./build/tileset.sql )"
echo "      : the tool source code: https://github.com/openmaptiles/openmaptiles-tools "
echo "      : but we generate code from this directory informations! "
docker run --rm -v $(pwd):/tileset openmaptiles/openmaptiles-tools make

echo " "
echo "====> : Start PostgreSQL service ; create PostgreSQL data volume "
echo "      : source code: https://github.com/openmaptiles/postgis "
echo "      : Thank you: https://www.postgresql.org !  Thank you http://postgis.org !"
docker-compose up   -d postgres
sleep 30

echo " "
echo "====> : Start Importing water data from http://openstreetmapdata.com  into PostgreSQL "
echo "      : source code:  https://github.com/openmaptiles/import-water "
echo "      : Data license: http://openstreetmapdata.com/info/license  "
echo "      : Thank you: http://openstreetmapdata.com/info/supporting "
docker-compose run --rm import-water

echo " "
echo "====> : Start importing  http://www.naturalearthdata.com  into PostgreSQL "
echo "      : source code: https://github.com/openmaptiles/import-natural-earth "
echo "      : term-of-use: http://www.naturalearthdata.com/about/terms-of-use  "
echo "      : Thank you: Natural Earth Contributors! "
docker-compose run --rm import-natural-earth

echo " "
echo "====> : Start importing OpenStreetMap Lakelines data "
echo "      : Source code: https://github.com/openmaptiles/import-lakelines "
echo "      :              https://github.com/lukasmartinelli/osm-lakelines "
echo "      : Data license: .. "
docker-compose run --rm import-lakelines

echo " "
echo "====> : Start importing OpenStreetMap data: ./data/${testdata} -> imposm3[./build/mapping.yaml] -> PostgreSQL"
echo "      : Imposm3 documentation: https://imposm.org/docs/imposm3/latest/index.html "
echo "      :   Thank you Omniscale! "
echo "      :   source code: https://github.com/openmaptiles/import-osm "
echo "      : The OpenstreetMap data license: https://www.openstreetmap.org/copyright (ODBL) "
echo "      : Thank you OpenStreetMap Contributors ! " 
docker-compose run --rm import-osm

echo " "
echo "====> : Start SQL postprocessing:  ./build/tileset.sql -> PostgreSQL "
echo "      : source code: https://github.com/openmaptiles/import-sql "
docker-compose run --rm import-sql

echo " "
echo "====> : Start generating MBTiles (containing gzipped MVT PBF) from a TM2Source project. "
echo "      : TM2Source project definitions : ./build/openmaptiles.tm2source/data.yml "
echo "      : output MBTiles: ./data/tiles.mbtiles  "
echo "      : source code: https://github.com/openmaptiles/generate-vectortiles "
echo "      : We are using a lot of Mapbox Open Source tools! : https://github.com/mapbox "
echo "      : Thank you https://www.mapbox.com !"
echo "      : See other MVT tools : https://github.com/mapbox/awesome-vector-tiles "
docker-compose -f docker-compose.yml -f docker-compose-test-override.yml  run --rm generate-vectortiles

echo " "
echo "====> : Stop PostgreSQL service ( but we keep PostgreSQL data volume for debugging )"
docker-compose stop postgres

ENDTIME=$(date +%s) 
ENDDATE=$(date -Iminutes)
MODDATE=$(stat -c  %y  ./data/${testdata} )

echo " "
echo " "
echo "------------------------------------------------------------"
echo "--                        Summary                         --"
echo "------------------------------------------------------------"
echo " "
echo " "
echo "====> : (disk space) We have created a lot of docker images: "
echo "      : hint: you can remove with:  docker rmi IMAGE "
docker images | grep openmaptiles

echo " "
echo "====> : (disk space) We have created this new docker volumes for PostgreSQL data:"
echo "      : hint: you can remove with : docker volume rm openmaptiles_pgdata "
docker volume ls -q | grep openmaptiles 

echo " "
echo "====> : (disk space) We have created the new vectortiles ( ./data/tiles.mbtiles ) "
echo "      : The OpenMapTiles MBTILES license: ..... "
echo "      : We created from $testdata ( file moddate: $MODDATE ) "
echo "      : Size: "
ls ./data/*.mbtiles -la

echo " "
echo "============================================================"
echo "The quickstart.sh is finished! "
echo "It takes $(($ENDTIME - $STARTTIME)) seconds to complete"
echo "We saved the log file to $log_file  ( for debugging ) "
echo " " 
echo "Start experimenting -> see the documentations!  "
echo "============================================================"



