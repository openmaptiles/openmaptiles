#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

##
##  OpenMapTiles quickstart.sh for x86_64 linux
##  

STARTTIME=$(date +%s)
STARTDATE=$(date -Iminutes)
githash=$( git rev-parse HEAD )

log_file=quickstart.log
rm -f $log_file
exec &> >(tee -a "$log_file")

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : OpenMapTiles quickstart! [ https://github.com/openmaptiles/openmaptiles ]    "
echo "      : This will be logged to the $log_file file ( for debugging ) and to the screen"
echo "      : Git version: $githash  / Started: $STARTDATE "
echo "      : Your bash version:  $BASH_VERSION"
echo "      : Your system is:"
lsb_release -a

echo " "
echo "-------------------------------------------------------------------------------------"
echo "      : This is working on x86_64 ; Your kernel is:"
uname -r
uname -m

echo "      : --- Memory, CPU info ---- "
mem=$( grep MemTotal /proc/meminfo | awk '{print $2}' | xargs -I {} echo "scale=4; {}/1024^2" | bc  )
echo "system memory (GB): ${mem}  "
grep SwapTotal /proc/meminfo
echo cpu number: $(grep -c processor /proc/cpuinfo) x $(cat /proc/cpuinfo | grep "bogomips" | head -1)
cat /proc/meminfo  | grep Free

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Please check the docker and docker-compose version!"
echo "      : We are using docker-compose V2 file format !  see more: https://docs.docker.com/"
echo "      : (theoretically;not tested) minumum Docker version is 1.10.0+."
echo "      : (theoretically;not tested) minimum Docker-compose version is 1.6.0+."
echo "      : See the .travis testfile for the current supported versions "
echo "      : Your docker systems is:"
docker         --version
docker-compose --version

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Checking OpenMapTiles docker images "
docker images | grep openmaptiles

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Stopping running services & removing old containers "
docker-compose down
docker-compose rm -fv

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : For a clean start, we are removing old postgresql data volume ( if it exists )"
docker volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Making directories - if they don't exist ( ./build ./data ) "
mkdir -p build
mkdir -p data

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Removing old MBTILES if exists ( ./data/*.mbtiles ) "
rm -f ./data/*.mbtiles

testdata=zurich_switzerland.osm.pbf
testdataurl=https://s3.amazonaws.com/metro-extracts.mapzen.com/$testdata
if [ !  -f ./data/${testdata} ]; then
    echo " "
    echo "-------------------------------------------------------------------------------------"
    echo "====> : Downloading testdata $testdata   "
    rm -f ./data/*
    wget $testdataurl  -P ./data
else
    echo " "
    echo "-------------------------------------------------------------------------------------"
    echo "====> : The testdata ./data/$testdata exists, we don't need to download! "    
fi

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Remove old generated source files ( ./build/* ) ( if they exist ) "
docker run --rm -v $(pwd):/tileset openmaptiles/openmaptiles-tools make clean_build

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Code generating from the layer definitions ( ./build/mapping.yaml; ./build/tileset.sql )"
echo "      : The tool source code: https://github.com/openmaptiles/openmaptiles-tools "
echo "      : But we generate the tm2source, Imposm mappings and SQL functions from the layer definitions! "
docker run --rm -v $(pwd):/tileset openmaptiles/openmaptiles-tools make

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start PostgreSQL service ; create PostgreSQL data volume "
echo "      : Source code: https://github.com/openmaptiles/postgis "
echo "      : Thank you: https://www.postgresql.org !  Thank you http://postgis.org !"
docker-compose up   -d postgres
sleep 30

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start importing water data from http://openstreetmapdata.com into PostgreSQL "
echo "      : Source code:  https://github.com/openmaptiles/import-water "
echo "      : Data license: http://openstreetmapdata.com/info/license  "
echo "      : Thank you: http://openstreetmapdata.com/info/supporting "
docker-compose run --rm import-water

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start importing  http://www.naturalearthdata.com  into PostgreSQL "
echo "      : Source code: https://github.com/openmaptiles/import-natural-earth "
echo "      : Terms-of-use: http://www.naturalearthdata.com/about/terms-of-use  "
echo "      : Thank you: Natural Earth Contributors! "
docker-compose run --rm import-natural-earth

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start importing OpenStreetMap Lakelines data "
echo "      : Source code: https://github.com/openmaptiles/import-lakelines "
echo "      :              https://github.com/lukasmartinelli/osm-lakelines "
echo "      : Data license: .. "
docker-compose run --rm import-lakelines

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start importing OpenStreetMap data: ./data/${testdata} -> imposm3[./build/mapping.yaml] -> PostgreSQL"
echo "      : Imposm3 documentation: https://imposm.org/docs/imposm3/latest/index.html "
echo "      :   Thank you Omniscale! "
echo "      :   Source code: https://github.com/openmaptiles/import-osm "
echo "      : The OpenstreetMap data license: https://www.openstreetmap.org/copyright (ODBL) "
echo "      : Thank you OpenStreetMap Contributors ! " 
docker-compose run --rm import-osm

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start SQL postprocessing:  ./build/tileset.sql -> PostgreSQL "
echo "      : Source code: https://github.com/openmaptiles/import-sql "
docker-compose run --rm import-sql

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start generating MBTiles (containing gzipped MVT PBF) from a TM2Source project. "
echo "      : TM2Source project definitions : ./build/openmaptiles.tm2source/data.yml "
echo "      : Output MBTiles: ./data/tiles.mbtiles  "
echo "      : Source code: https://github.com/openmaptiles/generate-vectortiles "
echo "      : We are using a lot of Mapbox Open Source tools! : https://github.com/mapbox "
echo "      : Thank you https://www.mapbox.com !"
echo "      : See other MVT tools : https://github.com/mapbox/awesome-vector-tiles "
echo "      :  "
echo "      : You will see a lot of deprecated warning in the log! This is normal!  "
echo "      :    like :  Mapnik LOG>  ... is deprecated and will be removed in Mapnik 4.x ... "

docker-compose -f docker-compose.yml -f docker-compose-test-override.yml  run --rm generate-vectortiles

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Stop PostgreSQL service ( but we keep PostgreSQL data volume for debugging )"
docker-compose stop postgres

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Inputs - Outputs md5sum for debugging "
rm -f quickstart_checklist.chk
md5sum build/mapping.yaml                     >> quickstart_checklist.chk
md5sum build/tileset.sql                      >> quickstart_checklist.chk
md5sum build/openmaptiles.tm2source/data.yml  >> quickstart_checklist.chk
md5sum ./data/${testdata}                     >> quickstart_checklist.chk
md5sum ./data/tiles.mbtiles                   >> quickstart_checklist.chk
cat quickstart_checklist.chk

ENDTIME=$(date +%s) 
ENDDATE=$(date -Iminutes)
MODDATE=$(stat -c  %y  ./data/${testdata} )

echo " "
echo " "
echo "-------------------------------------------------------------------------------------"
echo "--                           S u m m a r y                                         --"
echo "-------------------------------------------------------------------------------------"
echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : (disk space) We have created a lot of docker images: "
echo "      : Hint: you can remove with:  docker rmi IMAGE "
docker images | grep openmaptiles

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : (disk space) We have created this new docker volume for PostgreSQL data:"
echo "      : Hint: you can remove with : docker volume rm openmaptiles_pgdata "
docker volume ls -q | grep openmaptiles 

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : (disk space) We have created the new vectortiles ( ./data/tiles.mbtiles ) "
echo "      : The OpenMapTiles MBTILES license: ..... "
echo "      : We created from $testdata ( file moddate: $MODDATE ) "
echo "      : Size: "
ls ./data/*.mbtiles -la

echo " "
echo "-------------------------------------------------------------------------------------"
echo "The quickstart.sh is finished! "
echo "It takes $(($ENDTIME - $STARTTIME)) seconds to complete"
echo "We saved the log file to $log_file  ( for debugging ) You can compare with the travis log !"
echo " " 
echo "Start experimenting -> see the documentation!  "
echo "-------------------------------------------------------------------------------------"

