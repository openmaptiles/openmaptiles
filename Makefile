# Options to run with docker and docker-compose - ensure the container is destroyed on exit
# Containers run as the current user rather than root (so that created files are not root-owned)
DC_OPTS?=--rm -u $$(id -u $${USER}):$$(id -g $${USER})

# If running in the test mode, compare files rather than copy them
TEST_MODE?=no
ifeq ($(TEST_MODE),yes)
  # create images in ./build/devdoc and compare them to ./layers
  GRAPH_PARAMS=./build/devdoc ./layers
else
  # update graphs in the ./layers dir
  GRAPH_PARAMS=./layers
endif

.PHONY: all
all: build/openmaptiles.tm2source/data.yml build/mapping.yaml build-sql

.PHONY: help
help:
	@echo "=============================================================================="
	@echo " OpenMapTiles  https://github.com/openmaptiles/openmaptiles "
	@echo "Hints for testing areas                "
	@echo "  make download-geofabrik-list         # list actual geofabrik OSM extracts for download -> <<your-area>> "
	@echo "  make list                            # list actual geofabrik OSM extracts for download -> <<your-area>> "
	@echo "  ./quickstart.sh <<your-area>>        # example:  ./quickstart.sh madagascar "
	@echo "  "
	@echo "Hints for designers:"
	@echo "  make start-postserve                 # start Postserver + Maputnik Editor [ see localhost:8088 ] "
	@echo "  make start-tileserver                # start klokantech/tileserver-gl [ see localhost:8080 ] "
	@echo "  "
	@echo "Hints for developers:"
	@echo "  make                                 # build source code"
	@echo "  make download-geofabrik area=albania # download OSM data from geofabrik, and create config file"
	@echo "  make psql                            # start PostgreSQL console"
	@echo "  make psql-list-tables                # list all PostgreSQL tables"
	@echo "  make psql-vacuum-analyze             # PostgreSQL: VACUUM ANALYZE"
	@echo "  make psql-analyze                    # PostgreSQL: ANALYZE"
	@echo "  make generate-qareports              # generate reports [./build/qareports]"
	@echo "  make generate-devdoc                 # generate devdoc including graphs for all layers  [./layers/...]"
	@echo "  make tools-dev                       # start openmaptiles-tools /bin/bash terminal"
	@echo "  make db-destroy                      # remove docker containers and PostgreSQL data volume"
	@echo "  make db-start                        # start PostgreSQL, creating it if it doesn't exist"
	@echo "  make db-start-preloaded              # start PostgreSQL, creating data-prepopulated one if it doesn't exist"
	@echo "  make db-stop                         # stop PostgreSQL database without destroying the data"
	@echo "  make docker-unnecessary-clean        # clean unnecessary docker image(s) and container(s)"
	@echo "  make refresh-docker-images           # refresh openmaptiles docker images from Docker HUB"
	@echo "  make remove-docker-images            # remove openmaptiles docker images"
	@echo "  make pgclimb-list-views              # list PostgreSQL public schema views"
	@echo "  make pgclimb-list-tables             # list PostgreSQL public schema tables"
	@echo "  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM information"
	@echo "  cat  quickstart.log                  # backup of the last ./quickstart.sh"
	@echo "  make help                            # help about available commands"
	@echo "=============================================================================="

.PHONY: init-dirs
init-dirs:
	mkdir -p build/sql && mkdir -p data && mkdir -p cache

build/openmaptiles.tm2source/data.yml: init-dirs
	mkdir -p build/openmaptiles.tm2source
	docker-compose run $(DC_OPTS) openmaptiles-tools generate-tm2source openmaptiles.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > $@

build/mapping.yaml: init-dirs
	docker-compose run $(DC_OPTS) openmaptiles-tools generate-imposm3 openmaptiles.yaml > $@

.PHONY: build-sql
build-sql: init-dirs
	docker-compose run $(DC_OPTS) openmaptiles-tools generate-sql openmaptiles.yaml --dir ./build/sql

.PHONY: clean
clean:
	rm -rf build

.PHONY: db-destroy
db-destroy:
	docker-compose down -v --remove-orphans
	docker-compose rm -fv
	docker volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true
	rm -rf cache

.PHONY: db-start
db-start:
	docker-compose up --no-recreate -d postgres
	@echo "Wait for PostgreSQL to start..."
	docker-compose run $(DC_OPTS) openmaptiles-tools pgwait

.PHONY: db-start-preloaded
db-start-preloaded: export POSTGIS_IMAGE=openmaptiles/postgis-preloaded
db-start-preloaded: db-start

.PHONY: db-stop
db-stop:
	@echo "Stopping PostgreSQL..."
	docker-compose stop postgres

.PHONY: download-geofabrik
download-geofabrik: init-dirs
	@echo =============== download-geofabrik =======================
	@echo Download area:   $(area)
	@echo [[ example: make download-geofabrik area=albania ]]
	@echo [[ list areas:  make download-geofabrik-list     ]]
	docker-compose run $(DC_OPTS) openmaptiles-tools bash -c \
		'download-osm geofabrik $(area) \
		--minzoom $$QUICKSTART_MIN_ZOOM \
		--maxzoom $$QUICKSTART_MAX_ZOOM \
		--make-dc /import/docker-compose-config.yml -- -d /import'
	ls -la ./data/$(area)*
	@echo " "

.PHONY: psql
psql: db-start
	docker-compose run $(DC_OPTS) openmaptiles-tools psql.sh

.PHONY: import-osm
import-osm: db-start all
	docker-compose run $(DC_OPTS) openmaptiles-tools import-osm

.PHONY: import-osm-diff
import-osm-diff: db-start all
	docker-compose run $(DC_OPTS) openmaptiles-tools import-osm-diff

.PHONY: update-osm
update-osm: db-start all
	docker-compose run $(DC_OPTS) openmaptiles-tools import-update

.PHONY: import-data
import-data: db-start
	docker-compose run $(DC_OPTS) import-data

.PHONY: import-borders
import-borders: db-start
	docker-compose run $(DC_OPTS) openmaptiles-tools import-borders

.PHONY: import-sql
import-sql: db-start all
	docker-compose run $(DC_OPTS) openmaptiles-tools import-sql

.PHONY: generate-tiles
generate-tiles: init-dirs db-start all
	rm -rf data/tiles.mbtiles
	@if [ -f ./data/docker-compose-config.yml ]; then \
		echo "Generating tiles limited by ./data/docker-compose-config.yml ..."; \
		docker-compose -f docker-compose.yml -f ./data/docker-compose-config.yml \
					   run $(DC_OPTS) generate-vectortiles; \
	else \
		echo "Generating all tiles ..."; \
		docker-compose run $(DC_OPTS) generate-vectortiles; \
	fi
	@echo "Updating generated tile metadata ..."
	docker-compose run $(DC_OPTS) openmaptiles-tools generate-metadata ./data/tiles.mbtiles

.PHONY: start-tileserver
start-tileserver: init-dirs
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
	docker run $(DC_OPTS) -it --name tileserver-gl -v $$(pwd)/data:/data -p 8080:80 klokantech/tileserver-gl

.PHONY: start-postserve
start-postserve: db-start
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Bring up postserve at localhost:8090"
	@echo "*     --> can view it locally (use make start-maputnik)"
	@echo "*     --> or can use https://maputnik.github.io/editor"
	@echo "* "
	@echo "*  set data source / TileJSON URL to http://localhost:8090"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker-compose up -d postserve
	docker pull maputnik/editor


.PHONY: start-maputnik
start-maputnik: start-postserve
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Start maputnik/editor "
	@echo "*       ---> go to http://localhost:8088"
	@echo "*       ---> set data source / TileJSON URL to http://localhost:8090"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker rm -f maputnik_editor || true
	docker run $(DC_OPTS) --name maputnik_editor -d -p 8088:8888 maputnik/editor

.PHONY: generate-qareports
generate-qareports:
	./qa/run.sh

# generate all etl and mapping graphs
.PHONY: generate-devdoc
generate-devdoc: init-dirs
	mkdir -p ./build/devdoc && \
	docker-compose run $(DC_OPTS) -e TOOLS_VERSION=latest openmaptiles-tools sh -c \
			'generate-etlgraph openmaptiles.yaml $(GRAPH_PARAMS) && \
			 generate-mapping-graph openmaptiles.yaml $(GRAPH_PARAMS)'

.PHONY: tools-dev
tools-dev:
	docker-compose run $(DC_OPTS) openmaptiles-tools bash

# the `download-geofabrik` error message mention `list`, if the area parameter is wrong. so I created a similar make command
.PHONY: list
list: download-geofabrik-list

.PHONY: download-geofabrik-list
download-geofabrik-list:
	docker-compose run $(DC_OPTS) openmaptiles-tools download-osm list geofabrik

.PHONY: import-wikidata
import-wikidata:
	docker-compose run $(DC_OPTS) openmaptiles-tools import-wikidata --cache /import/wikidata-cache.json openmaptiles.yaml

.PHONY: psql-pg-stat-reset
psql-pg-stat-reset:
	docker-compose run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'SELECT pg_stat_statements_reset();'

.PHONY: list-views
list-views:
	@docker-compose run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -A -F"," -P pager=off -P footer=off \
		-c "select schemaname, viewname from pg_views where schemaname='public' order by viewname;"

.PHONY: list-tables
list-tables:
	@docker-compose run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -A -F"," -P pager=off -P footer=off \
		-c "select schemaname, tablename from pg_tables where schemaname='public' order by tablename;"

.PHONY: psql-list-tables
psql-list-tables:
	docker-compose run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c "\d+"

.PHONY: psql-vacuum-analyze
psql-vacuum-analyze:
	@echo "Start - postgresql: VACUUM ANALYZE VERBOSE;"
	docker-compose run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'VACUUM ANALYZE VERBOSE;'

.PHONY: psql-analyze
psql-analyze:
	@echo "Start - postgresql: ANALYZE VERBOSE;"
	docker-compose run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'ANALYZE VERBOSE;'

.PHONY: list-docker-images
list-docker-images:
	docker images | grep openmaptiles

.PHONY: refresh-docker-images
refresh-docker-images:
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "docker-compose pull --ignore-pull-failures"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	@echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
	#docker-compose pull --ignore-pull-failures

.PHONY: remove-docker-images
remove-docker-images:
	@echo "Deleting all openmaptiles related docker image(s)..."
	@docker-compose down
	@docker images | grep "openmaptiles" | awk -F" " '{print $$3}' | xargs --no-run-if-empty docker rmi -f
	@docker images | grep "osm2vectortiles/mapbox-studio" | awk -F" " '{print $$3}' | xargs --no-run-if-empty docker rmi -f
	@docker images | grep "klokantech/tileserver-gl"      | awk -F" " '{print $$3}' | xargs --no-run-if-empty docker rmi -f

.PHONY: docker-unnecessary-clean
docker-unnecessary-clean:
	@echo "Deleting unnecessary container(s)..."
	@docker ps -a  | grep Exited | awk -F" " '{print $$1}' | xargs  --no-run-if-empty docker rm
	@echo "Deleting unnecessary image(s)..."
	@docker images | grep \<none\> | awk -F" " '{print $$3}' | xargs  --no-run-if-empty  docker rmi

.PHONY: test-perf-null
test-perf-null:
	docker-compose run $(DC_OPTS) openmaptiles-tools test-perf openmaptiles.yaml --test null --no-color
