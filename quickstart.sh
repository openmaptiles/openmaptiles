#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset


###########################################
# OpenMapTiles quickstart.sh for x86_64 linux
#
# Example calls ...
# ./quickstart.sh
# ./quickstart.sh africa
# ./quickstart.sh alabama
# ./quickstart.sh alaska
# ./quickstart.sh albania
# ./quickstart.sh alberta
# ./quickstart.sh alps
# ....
#
# to list areas :  make download-geofabrik-list
# see more QUICKSTART.md
#

if [ $# -eq 0 ]; then
    osm_area=albania                         #  default test country
    echo "No parameter - set area=$osm_area "
else
    osm_area=$1
fi
testdata="${osm_area}-latest.osm.pbf"

##  Min versions ...
MIN_COMPOSE_VER=1.7.1
MIN_DOCKER_VER=1.12.3
STARTTIME=$(date +%s)
STARTDATE=$(date +"%Y-%m-%dT%H:%M%z")
githash=$( git rev-parse HEAD )

log_file=./quickstart.log
rm -f $log_file
echo " "
echo "====================================================================================="
echo "                       Docker check & Download images                                "
echo "-------------------------------------------------------------------------------------"
echo "====> : Please check the Docker and docker-compose version!"
echo "      : We are using docker-compose v2 file format!  see more at https://docs.docker.com/"
echo "      : Minimum required Docker version: $MIN_DOCKER_VER+"
echo "      : Minimum required docker-compose version: $MIN_COMPOSE_VER+"
echo "      : See the .travis build for the currently supported versions."
echo "      : Your docker system:"
docker         --version
docker-compose --version

# based on: http://stackoverflow.com/questions/16989598/bash-comparing-version-numbers
function version { echo "$@" | tr -cs '0-9.' '.' | awk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }'; }

COMPOSE_VER=$(docker-compose version --short)
if [ "$(version "$COMPOSE_VER")" -lt "$(version "$MIN_COMPOSE_VER")" ]; then
  echo "ERR: Your Docker-compose version is Known to have bugs , Please Update docker-compose!"
  exit 1
fi

DOCKER_VER="$(docker -v | awk -F '[ ,]+' '{ print $3 }')"
if [ "$(version "$DOCKER_VER")" -lt "$(version "$MIN_DOCKER_VER")" ]; then
  echo "ERR: Your Docker version is not compatible. Please Update docker!"
  exit 1
fi

# If there are no arguments, or just the area is set, use preloaded docker image to speed up
# to force all steps, use two arguments, e.g. "./quickstart monaco empty"
(( $# == 0 || $# == 1 )) && USE_PRELOADED_IMAGE=true || USE_PRELOADED_IMAGE=""
export USE_PRELOADED_IMAGE

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Pulling or refreshing OpenMapTiles docker images "
make refresh-docker-images


#####  backup log from here ...
exec &> >(tee -a "$log_file")

echo " "
echo "====================================================================================="
echo "                                Start processing                                     "
echo "-------------------------------------------------------------------------------------"
echo "====> : OpenMapTiles quickstart! [ https://github.com/openmaptiles/openmaptiles ]    "
echo "      : This will be logged to the $log_file file (for debugging) and to the screen"
echo "      : Area             : $osm_area "
echo "      : Preloaded Image  : $USE_PRELOADED_IMAGE "
echo "      : Git version      : $githash "
echo "      : Started          : $STARTDATE "
echo "      : Your bash version: $BASH_VERSION"
echo "      : Your OS          : $OSTYPE"
docker         --version
docker-compose --version

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo " "
    echo "-------------------------------------------------------------------------------------"
    echo "      : This is working on x86_64 ; Your kernel is:"
    uname -r
    uname -m

    KERNEL_CPU_VER=$(uname -m)
    if [ "$KERNEL_CPU_VER" != "x86_64" ]; then
      echo "ERR: Sorry this is working only on x86_64!"
      exit 1
    fi
    echo "      : --- Memory, CPU info ---- "
    mem=$( grep MemTotal /proc/meminfo | awk '{print $2}' | xargs -I {} echo "scale=4; {}/1024^2" | bc  )
    echo "system memory (GB): ${mem}"
    grep SwapTotal /proc/meminfo
    echo "cpu number: $(grep -c processor /proc/cpuinfo) x $(grep "bogomips" /proc/cpuinfo | head -1)"
    grep Free /proc/meminfo
else
    echo " "
    echo "Warning : Platforms other than Linux are less tested"
    echo " "
fi

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Stopping running services & removing old containers"
make db-destroy

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Existing OpenMapTiles docker images. Will use version $(source .env && echo "$TOOLS_VERSION")"
docker images | grep openmaptiles

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Create directories if they don't exist"
make init-dirs

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Removing old MBTILES if exists ( ./data/*.mbtiles ) "
rm -f ./data/*.mbtiles

if [[ ! -f "./data/${testdata}" || ! -f "./data/docker-compose-config.yml" ]]; then
    echo " "
    echo "-------------------------------------------------------------------------------------"
    echo "====> : Downloading ${osm_area} from Geofabrik..."
    rm -rf ./data/*
    make download-geofabrik "area=${osm_area}"
else
    echo " "
    echo "-------------------------------------------------------------------------------------"
    echo "====> : The testdata ./data/$testdata exists, we don't need to download!"
fi


if [ !  -f "./data/${testdata}" ]; then
    echo " "
    echo "Missing ./data/$testdata , Download or Parameter error? "
    exit 1
fi

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Remove old generated source files ( ./build/* ) ( if they exist ) "
make clean

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Code generating from the layer definitions ( ./build/mapping.yaml; ./build/sql/* )"
echo "      : The tool source code: https://github.com/openmaptiles/openmaptiles-tools "
echo "      : But we generate the tm2source, Imposm mappings and SQL functions from the layer definitions! "
make all

echo " "
echo "-------------------------------------------------------------------------------------"
if [[ "$USE_PRELOADED_IMAGE" == true ]]; then
  echo "====> : Start PostgreSQL service using postgis image preloaded with this data:"
  echo "      : * Water data from http://osmdata.openstreetmap.de"
  echo "      :   Data license: https://osmdata.openstreetmap.de/info/license.html"
  echo "      : * Natural Earth from http://www.naturalearthdata.com"
  echo "      :   Terms-of-use: http://www.naturalearthdata.com/about/terms-of-use"
  echo "      : * OpenStreetMap Lakelines data https://github.com/lukasmartinelli/osm-lakelines"
  echo "      :"
  echo "      : Source code: https://github.com/openmaptiles/openmaptiles-tools/tree/master/docker/import-data"
  echo "      :   includes all data from the import-data image"
  echo "      :"
  echo "      : Use two-parameter quickstart to start with an empty database:"
  echo "      :   ./quickstart.sh albania empty"
  echo "      : If desired, you can manually import data by one using these commands:"
  echo "      :   make db-destroy"
  echo "      :   make db-start"
  echo "      :   make import-data"
  echo "      :"
  echo "      : Source code: https://github.com/openmaptiles/openmaptiles-tools/tree/master/docker/postgis-preloaded"
  echo "      : Thank you: https://www.postgresql.org !  Thank you http://postgis.org !"
  make db-start-preloaded
else
  echo "====> : Start PostgreSQL service using empty database and importing all the data:"
  echo "      : * Water data from http://osmdata.openstreetmap.de"
  echo "      :   Data license: https://osmdata.openstreetmap.de/info/license.html"
  echo "      : * Natural Earth from http://www.naturalearthdata.com"
  echo "      :   Terms-of-use: http://www.naturalearthdata.com/about/terms-of-use"
  echo "      : * OpenStreetMap Lakelines data https://github.com/lukasmartinelli/osm-lakelines"
  echo "      :"
  echo "      : Source code: https://github.com/openmaptiles/openmaptiles-tools/tree/master/docker/import-data"
  echo "      :   includes all data from the import-data image"
  echo "      :"
  echo "      : Thank you: https://www.postgresql.org !  Thank you http://postgis.org !"
  make db-start
  make import-data
fi

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start importing OpenStreetMap data: ./data/${testdata} -> imposm3[./build/mapping.yaml] -> PostgreSQL"
echo "      : Imposm3 documentation: https://imposm.org/docs/imposm3/latest/index.html "
echo "      :   Thank you Omniscale! "
echo "      :   Source code: https://github.com/openmaptiles/openmaptiles-tools/tree/master/docker/import-osm "
echo "      : The OpenstreetMap data license: https://www.openstreetmap.org/copyright (ODBL) "
echo "      : Thank you OpenStreetMap Contributors ! "
make import-osm

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start importing border data from ./data/${testdata} into PostgreSQL using osmborder"
echo "      : Source code: https://github.com/pnorman/osmborder"
echo "      : Data license: http://www.openstreetmap.org/copyright"
echo "      : Thank you: Paul Norman"
make import-borders

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start importing Wikidata: Wikidata Query Service -> PostgreSQL"
echo "      : The Wikidata license: CC0 - https://www.wikidata.org/wiki/Wikidata:Main_Page "
echo "      : Thank you Wikidata Contributors ! "
make import-wikidata

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start SQL postprocessing:  ./build/sql/* -> PostgreSQL "
echo "      : Source code: https://github.com/openmaptiles/openmaptiles-tools/blob/master/bin/import-sql"
# If the output contains a WARNING, stop further processing
# Adapted from https://unix.stackexchange.com/questions/307562
make import-sql

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Analyze PostgreSQL tables"
make psql-analyze

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Testing PostgreSQL tables to match layer definitions metadata"
make test-perf-null

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start generating MBTiles (containing gzipped MVT PBF) from a TM2Source project. "
echo "      : TM2Source project definitions : ./build/openmaptiles.tm2source/data.yml "
echo "      : Output MBTiles: ./data/tiles.mbtiles  "
echo "      : Source code: https://github.com/openmaptiles/openmaptiles-tools/tree/master/docker/generate-vectortiles "
echo "      : We are using a lot of Mapbox Open Source tools! : https://github.com/mapbox "
echo "      : Thank you https://www.mapbox.com !"
echo "      : See other MVT tools : https://github.com/mapbox/awesome-vector-tiles "
echo "      :  "
echo "      : You will see a lot of deprecated warning in the log! This is normal!  "
echo "      :    like :  Mapnik LOG>  ... is deprecated and will be removed in Mapnik 4.x ... "
make generate-tiles

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Stop PostgreSQL service ( but we keep PostgreSQL data volume for debugging )"
make db-stop

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Inputs - Outputs md5sum for debugging "
rm -f ./data/quickstart_checklist.chk
{
  find build -type f | sort | xargs md5sum ;
  find data -type f | sort | xargs md5sum ;
} >> ./data/quickstart_checklist.chk
cat ./data/quickstart_checklist.chk

ENDTIME=$(date +%s)
if stat --help >/dev/null 2>&1; then
  MODDATE=$(stat -c %y "./data/${testdata}" )
else
  MODDATE=$(stat -f%Sm -t '%F %T %z' "./data/${testdata}" )
fi

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
echo "====> : (disk space) We have created the new vectortiles ( ./data/tiles.mbtiles ) "
echo "      : Please respect the licenses (OdBL for OSM data) of the sources when distributing the MBTiles file."
echo "      : Created from $testdata ( file moddate: $MODDATE ) "
echo "      : Size: "
ls -la ./data/*.mbtiles

echo " "
echo "-------------------------------------------------------------------------------------"
echo "The ./quickstart.sh $osm_area  is finished! "
echo "It takes $((ENDTIME - STARTTIME)) seconds to complete"
echo "We saved the log file to $log_file  ( for debugging ) You can compare with the travis log !"
echo " "
echo "Start experimenting! And check the QUICKSTART.MD file!"
echo " "
echo "*  Use   make maputnik-start     to explore tile generation on request"
echo "*  Use   make tileserver-start   to view pre-generated tiles"
echo " "
echo "Available help commands (make help)  "
make help

echo "-------------------------------------------------------------------------------------"
echo " Acknowledgments "
echo " Generated vector tiles are produced work of OpenStreetMap data. "
echo " Such tiles are reusable under CC-BY license granted by OpenMapTiles team: "
echo "   https://github.com/openmaptiles/openmaptiles/#license "
echo " Maps made with these vector tiles must display a visible credit: "
echo "   © OpenMapTiles © OpenStreetMap contributors "
echo " "
echo " Thanks to all free, open source software developers and Open Data Contributors!    "
echo "-------------------------------------------------------------------------------------"
