#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset


###########################################
# OpenMapTiles quickstart.sh for x86_64 linux
#
# Usage:
#   ./quickstart.sh [--empty] [area [geofabrik|osmfr|bbbike]]
#
# Use a preloaded docker image to speed up, unless the --empty flag is used.
#
# Servers:
#   geofabik: http://download.geofabrik.de (default)
#   osmfr:    http://download.openstreetmap.fr (default for hierarchical area names)
#   bbbike:   https://www.bbbike.org (default for capitalized area names)
#
# Example calls ...
# ./quickstart.sh
# ./quickstart.sh africa
# ./quickstart.sh africa geofabrik
# ./quickstart.sh africa osmfr
# ./quickstart.sh alabama
# ./quickstart.sh alaska
# ./quickstart.sh albania
# ./quickstart.sh alberta
# ./quickstart.sh alps
# ./quickstart.sh europe/austria
# ./quickstart.sh europe/austria/salzburg osmfr
# ./quickstart.sh Adelaide
# ./quickstart.sh Adelaide bbbike
# ....
#
# to list geofabrik areas:  make list-geofabrik or make list-bbbike
# see more QUICKSTART.md
#

# If --empty is not given, use preloaded docker image to speed up
if [ $# -gt 0 ] && [[ $1 == --empty ]]; then
  export USE_PRELOADED_IMAGE=""
  shift
else
  export USE_PRELOADED_IMAGE=true
fi

if [ $# -eq 0 ]; then
  #  default test area
  export area=albania
  echo "No parameter - set area=$area "
else
  export area=$1
fi

if [ $# -eq 2 ]; then
  osm_server=$2
fi

##  Min versions ...
MIN_COMPOSE_VER=1.7.1
MIN_DOCKER_VER=1.12.3
STARTTIME=$(date +%s)
STARTDATE=$(date +"%Y-%m-%dT%H:%M%z")

log_file=./quickstart.log
rm -f $log_file
echo " "
echo "====================================================================================="
echo "                       Docker check & Download images                                "
echo "-------------------------------------------------------------------------------------"
echo "====> : Please check the Docker and docker-compose version!"
echo "      : We are using docker-compose v3 file format!  see more at https://docs.docker.com/"
echo "      : Minimum required Docker version: $MIN_DOCKER_VER+"
echo "      : Minimum required docker-compose version: $MIN_COMPOSE_VER+"
echo "      : See the .travis build for the currently supported versions."
echo "      : Your docker system:"

if ! command -v docker-compose &> /dev/null; then
  DOCKER_COMPOSE_HYPHEN=false
else
  DOCKER_COMPOSE_HYPHEN=true
fi

function docker_compose_command () {
    if $DOCKER_COMPOSE_HYPHEN; then
      docker-compose $@
    else
      docker compose $@
    fi
}

docker         --version
docker_compose_command --version

# based on: http://stackoverflow.com/questions/16989598/bash-comparing-version-numbers
function version { echo "$@" | tr -d 'v' | tr -cs '0-9.' '.' | awk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }'; }

COMPOSE_VER=$(docker_compose_command version --short)
if [ "$(version "$COMPOSE_VER")" -lt "$(version "$MIN_COMPOSE_VER")" ]; then
  echo "ERR: Your Docker-compose version is known to have bugs, please update docker-compose!"
  exit 1
fi

DOCKER_VER="$(docker -v | awk -F '[ ,]+' '{ print $3 }')"
if [ "$(version "$DOCKER_VER")" -lt "$(version "$MIN_DOCKER_VER")" ]; then
  echo "ERR: Your Docker version is not compatible. Please Update docker!"
  exit 1
fi

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
echo "      : Area             : $area "
echo "      : Download server  : ${osm_server:-unset (automatic)} "
echo "      : Preloaded image  : $USE_PRELOADED_IMAGE "
echo "      : Git version      : $(git rev-parse HEAD) "
echo "      : Started          : $STARTDATE "
echo "      : Your bash version: $BASH_VERSION"
echo "      : Your OS          : $OSTYPE"
docker         --version
docker_compose_command --version

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
    if [ -n "$(command -v bc)" ]; then
        mem=$( grep MemTotal /proc/meminfo | awk '{print $2}' | xargs -I {} echo "scale=4; {}/1024^2" | bc )
        echo "System memory (GB): ${mem}"
    else
        mem=$( grep MemTotal /proc/meminfo | awk '{print $2}')
        echo "System memory (KB): ${mem}"
    fi
    grep SwapTotal /proc/meminfo
    echo "CPU number: $(grep -c processor /proc/cpuinfo) x $(grep "bogomips" /proc/cpuinfo | head -1)"
    grep Free /proc/meminfo
else
    echo " "
    echo "Warning : Platforms other than Linux are less tested"
    echo " "
fi

# override the output filename based on the area if the default `tiles.mbtiles` is found
if [[ "$(source .env ; echo "$MBTILES_FILE")" = "tiles.mbtiles" ]]; then
  MBTILES_FILENAME=${area}.mbtiles
else
  MBTILES_FILENAME=$(source .env ; echo "$MBTILES_FILE")
fi

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Stopping running services & removing old containers"
make destroy-db

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
echo "====> : Removing old MBTILES if exists ( ./data/$MBTILES_FILENAME ) "
rm -f "./data/$MBTILES_FILENAME"

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Downloading ${area} from ${osm_server:-any source}..."
make "download${osm_server:+-${osm_server}}"

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
  echo "      : * OpenStreetMap Lakelines data https://github.com/openmaptiles/osm-lakelines"
  echo "      :"
  echo "      : Source code: https://github.com/openmaptiles/openmaptiles-tools/tree/master/docker/import-data"
  echo "      :   includes all data from the import-data image"
  echo "      :"
  echo "      : Use the --empty flag to start with an empty database:"
  echo "      :   ./quickstart.sh --empty albania "
  echo "      : If desired, you can manually import data by using these commands:"
  echo "      :   make destroy-db"
  echo "      :   make start-db"
  echo "      :   make import-data"
  echo "      :"
  echo "      : Source code: https://github.com/openmaptiles/openmaptiles-tools/tree/master/docker/postgis-preloaded"
  echo "      : Thank you https://www.postgresql.org !  Thank you http://postgis.org !"
  make start-db-preloaded
else
  echo "====> : Start PostgreSQL service using empty database and importing all the data:"
  echo "      : * Water data from http://osmdata.openstreetmap.de"
  echo "      :   Data license: https://osmdata.openstreetmap.de/info/license.html"
  echo "      : * Natural Earth from http://www.naturalearthdata.com"
  echo "      :   Terms-of-use: http://www.naturalearthdata.com/about/terms-of-use"
  echo "      : * OpenStreetMap Lakelines data https://github.com/openmaptiles/osm-lakelines"
  echo "      :"
  echo "      : Source code: https://github.com/openmaptiles/openmaptiles-tools/tree/master/docker/import-data"
  echo "      :   includes all data from the import-data image"
  echo "      :"
  echo "      : Thank you https://www.postgresql.org !  Thank you http://postgis.org !"
  make start-db
  make import-data
fi

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start importing OpenStreetMap data: ${area} -> imposm3[./build/mapping.yaml] -> PostgreSQL"
echo "      : Imposm3 documentation: https://imposm.org/docs/imposm3/latest/index.html "
echo "      :   Thank you Omniscale! "
echo "      :   Source code: https://github.com/openmaptiles/openmaptiles-tools/blob/master/bin/import-osm "
echo "      : The OpenstreetMap data license: https://www.openstreetmap.org/copyright (ODBL) "
echo "      : Thank you OpenStreetMap Contributors ! "
make import-osm

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
make analyze-db

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Testing PostgreSQL tables to match layer definitions metadata"
make test-perf-null

echo " "
echo "-------------------------------------------------------------------------------------"

if [[ "$(source .env ; echo "$BBOX")" = "-180.0,-85.0511,180.0,85.0511" ]]; then
  if [[ "$area" != "planet" ]]; then
    echo "====> : Compute bounding box for tile generation"
    make generate-bbox-file ${MIN_ZOOM:+MIN_ZOOM="${MIN_ZOOM}"} ${MAX_ZOOM:+MAX_ZOOM="${MAX_ZOOM}"}
  else
    echo "====> : Skipping bbox calculation when generating the entire planet"
  fi

else
  echo "====> : Bounding box is set in .env file"
fi

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Start generating MBTiles (containing gzipped MVT PBF) using PostGIS. "
echo "      : Output MBTiles: $MBTILES_FILENAME  "
echo "      : Source code: https://github.com/openmaptiles/openmaptiles-tools/blob/master/bin/generate-tiles "
MBTILES_FILE=$MBTILES_FILENAME make generate-tiles-pg

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Stop PostgreSQL service ( but we keep PostgreSQL data volume for debugging )"
make stop-db

echo " "
echo "-------------------------------------------------------------------------------------"
echo "====> : Inputs - Outputs md5sum for debugging "
rm -f ./data/quickstart_checklist.chk
{
  find build data -type f -exec md5sum {} + | sort -k2
} >> ./data/quickstart_checklist.chk
cat ./data/quickstart_checklist.chk

ENDTIME=$(date +%s)

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
echo "====> : (disk space) We have created the new vectortiles ( ./data/$MBTILES_FILENAME ) "
echo "      : Please respect the licenses (OdBL for OSM data) of the sources when distributing the MBTiles file."
echo "      : Data directory content:"
ls -la ./data

echo " "
echo "-------------------------------------------------------------------------------------"
echo "The ./quickstart.sh $area  is finished! "
echo "It took $((ENDTIME - STARTTIME)) seconds to complete"
echo "We saved the log file to $log_file  (for debugging) You can compare with the travis log !"
echo " "
echo "Start experimenting and check the QUICKSTART.MD file!"
echo " "
echo "*  Use   make start-maputnik     to explore tile generation on request"
echo "*  Use   make start-tileserver   to view pre-generated tiles"
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
