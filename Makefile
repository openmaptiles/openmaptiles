all: build/openmaptiles.tm2source/data.yml build/mapping.yaml build/tileset.sql

help:
	@echo "=============================================================================="
	@echo " OpenMapTiles  https://github.com/openmaptiles/openmaptiles "
	@echo "Hints for testing areas                "
	@echo "  make download-geofabrik-list         # list actual geofabrik OSM extracts for download -> <<your-area>> "
	@echo "  make list                            # list actual geofabrik OSM extracts for download -> <<your-area>> "
	@echo "  ./quickstart.sh <<your-area>>        # example:  ./quickstart.sh madagascar "
	@echo "  "
	@echo "Hints for designers:"
	@echo "  ....TODO....                         # start Maputnik "
	@echo "  make start-tileserver                # start klokantech/tileserver-gl [ see localhost:8080 ] "
	@echo "  make start-mapbox-studio             # start Mapbox Studio"
	@echo "  "
	@echo "Hints for developers:"
	@echo "  make                                 # build source code  "
	@echo "  make download-geofabrik area=albania # download OSM data from geofabrik, and create config file"
	@echo "  make psql                            # start PostgreSQL console "
	@echo "  make psql-list-tables                # list all PostgreSQL tables "
	@echo "  make psql-vacuum-analyze             # PostgreSQL: VACUUM ANALYZE"
	@echo "  make psql-analyze                    # PostgreSQL: ANALYZE"
	@echo "  make generate-qareports              # generate reports [./build/qareports]"
	@echo "  make generate-devdoc                 # generate devdoc  [./build/devdoc]"
	@echo "  make import-sql-dev                  # start import-sql  /bin/bash terminal "
	@echo "  make import-osm-dev                  # start import-osm  /bin/bash terminal (imposm3)"
	@echo "  make clean-docker                    # remove docker containers, PG data volume "
	@echo "  make forced-clean-sql                # drop all PostgreSQL tables for clean environment "
	@echo "  make docker-unnecessary-clean        # clean unnecessary docker image(s) and container(s)"
	@echo "  make refresh-docker-images           # refresh openmaptiles docker images from Docker HUB"
	@echo "  make remove-docker-images            # remove openmaptiles docker images"
	@echo "  make pgclimb-list-views              # list PostgreSQL public schema views"
	@echo "  make pgclimb-list-tables             # list PostgreSQL public schema tabless"
	@echo "  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM informations"
	@echo "  cat ./quickstart.log                 # backup  of the last ./quickstart.sh "
	@echo "  make help                            # help about avaialable commands"
	@echo "=============================================================================="

build/openmaptiles.tm2source/data.yml:
	mkdir -p build/openmaptiles.tm2source && generate-tm2source openmaptiles.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > build/openmaptiles.tm2source/data.yml

build/mapping.yaml:
	mkdir -p build && generate-imposm3 openmaptiles.yaml > build/mapping.yaml

build/tileset.sql:
	mkdir -p build && generate-sql openmaptiles.yaml > build/tileset.sql

clean:
	rm -f build/openmaptiles.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql

clean-docker:
	docker-compose down -v --remove-orphans
	docker-compose rm -fv
	docker volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true

list-docker-images:
	docker images | grep openmaptiles

refresh-docker-images:
	docker-compose pull --ignore-pull-failures

remove-docker-images:
	@echo "Deleting all openmaptiles related docker image(s)..."
	@docker-compose down
	@docker images | grep "openmaptiles" | awk -F" " '{print $$3}' | xargs --no-run-if-empty docker rmi -f
	@docker images | grep "osm2vectortiles/mapbox-studio" | awk -F" " '{print $$3}' | xargs --no-run-if-empty docker rmi -f
	@docker images | grep "klokantech/tileserver-gl"      | awk -F" " '{print $$3}' | xargs --no-run-if-empty docker rmi -f

docker-unnecessary-clean:
	@echo "Deleting unnecessary container(s)..."
	@docker ps -a  | grep Exited | awk -F" " '{print $$1}' | xargs  --no-run-if-empty docker rm
	@echo "Deleting unnecessary image(s)..."
	@docker images | grep \<none\> | awk -F" " '{print $$3}' | xargs  --no-run-if-empty  docker rmi

psql:
	docker-compose run --rm import-osm /usr/src/app/psql.sh

psql-list-tables:
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c "\d+"

psql-pg-stat-reset:
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c 'SELECT pg_stat_statements_reset();'

forced-clean-sql:
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "DROP SCHEMA IF EXISTS public CASCADE ; CREATE SCHEMA IF NOT EXISTS public; "
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "CREATE EXTENSION hstore; CREATE EXTENSION postgis; CREATE EXTENSION unaccent; CREATE EXTENSION fuzzystrmatch; CREATE EXTENSION osml10n; CREATE EXTENSION pg_stat_statements;"
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "GRANT ALL ON SCHEMA public TO public;COMMENT ON SCHEMA public IS 'standard public schema';"

pgclimb-list-views:
	docker-compose run --rm import-osm /usr/src/app/pgclimb.sh -c "select schemaname,viewname from pg_views where schemaname='public' order by viewname;" csv

pgclimb-list-tables:
	docker-compose run --rm import-osm /usr/src/app/pgclimb.sh -c "select schemaname,tablename from pg_tables where schemaname='public' order by tablename;" csv

psql-vacuum-analyze:
	@echo "Start - postgresql: VACUUM ANALYZE VERBOSE;"
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c 'VACUUM ANALYZE VERBOSE;'

psql-analyze:
	@echo "Start - postgresql: ANALYZE VERBOSE ;"
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c 'ANALYZE VERBOSE;'

import-sql-dev:
	docker-compose run --rm import-sql /bin/bash

import-osm-dev:
	docker-compose run --rm import-osm /bin/bash

download-geofabrik:
	@echo ===============  download-geofabrik =======================
	@echo Download area :   $(area)
	@echo [[ example: make download-geofabrik  area=albania ]]
	@echo [[ list areas:  make download-geofabrik-list       ]]
	docker-compose run --rm import-osm  ./download-geofabrik.sh $(area)
	ls -la ./data/$(area).*
	@echo "Generated config file: ./data/docker-compose-config.yml"
	@echo " "
	cat ./data/docker-compose-config.yml
	@echo " "

# the `download-geofabrik` error message mention `list`, if the area parameter is wrong. so I created a similar make command
list:
	docker-compose run --rm import-osm  ./download-geofabrik-list.sh

# same as a `make list`
download-geofabrik-list:
	docker-compose run --rm import-osm  ./download-geofabrik-list.sh

start-tileserver:
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Download/refresh klokantech/tileserver-gl docker image"
	@echo "* see documentation: https://github.com/klokantech/tileserver-gl"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker pull klokantech/tileserver-gl
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Start klokantech/tileserver-gl "
	@echo "*       ----------------------------> check localhost:8080 "
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker run -it --rm -v $$(pwd)/data:/data -p 8080:80 klokantech/tileserver-gl

start-mapbox-studio:
	docker-compose up mapbox-studio

generate-qareports:
	./qa/run.sh

# work in progress - please don't remove
generate-devdoc:
	mkdir -p ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/aeroway/aeroway.yaml               ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/boundary/boundary.yaml             ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/building/building.yaml             ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/housenumber/housenumber.yaml       ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/landcover/landcover.yaml           ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/landuse/landuse.yaml               ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/park/park.yaml                     ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/place/place.yaml                   ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/poi/poi.yaml                       ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/transportation/transportation.yaml ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/transportation_name/transportation_name.yaml ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/water/water.yaml                   ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/water_name/water_name.yaml         ./build/devdoc
	docker run --rm -v $$(pwd):/tileset openmaptiles/openmaptiles-tools generate-etlgraph layers/waterway/waterway.yaml             ./build/devdoc
