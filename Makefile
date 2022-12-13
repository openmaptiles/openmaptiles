#
# First section - common variable initialization
#

# Ensure that errors don't hide inside pipes
SHELL         = /bin/bash
.SHELLFLAGS   = -o pipefail -c

# Make all .env variables available for make targets
include .env

# Layers definition and meta data
TILESET_FILE ?= openmaptiles.yaml

# Options to run with docker and docker-compose - ensure the container is destroyed on exit
# Containers run as the current user rather than root (so that created files are not root-owned)
DC_OPTS ?= --rm --user=$(shell id -u):$(shell id -g)

# If set to a non-empty value, will use postgis-preloaded instead of postgis docker image
USE_PRELOADED_IMAGE ?=

# Local port to use with postserve
PPORT ?= 8090
export PPORT
# Local port to use with tileserver
TPORT ?= 8080
export TPORT

# Allow a custom docker-compose project name
ifeq ($(strip $(DC_PROJECT)),)
  DC_PROJECT := $(notdir $(shell pwd))
  DOCKER_COMPOSE := docker-compose
else
  DOCKER_COMPOSE := docker-compose --project-name $(DC_PROJECT)
endif

# Make some operations quieter (e.g. inside the test script)
ifeq ($(strip $(QUIET)),)
  QUIET_FLAG :=
else
  QUIET_FLAG := --quiet
endif

# Use `xargs --no-run-if-empty` flag, if supported
XARGS := xargs $(shell xargs --no-run-if-empty </dev/null 2>/dev/null && echo --no-run-if-empty)

# If running in the test mode, compare files rather than copy them
TEST_MODE?=no
ifeq ($(TEST_MODE),yes)
  COPY_TO_GIT=diff
else
  COPY_TO_GIT=cp
endif

.PHONY: all
all: init-dirs build/openmaptiles.tm2source/data.yml build/mapping.yaml build-sql

.PHONY: init-dirs
init-dirs:
	@mkdir -p build/sql/parallel
	@mkdir -p build/openmaptiles.tm2source
	@mkdir -p data
	@mkdir -p cache
	@ ! ($(DOCKER_COMPOSE) 2>/dev/null run $(DC_OPTS) openmaptiles-tools df --output=fstype /tileset| grep -q 9p) < /dev/null || ($(win_fs_error))


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
	@echo "  make generate-devdoc                 # generate devdoc including graphs for all layers  [./build/devdoc]"
	@echo "  make etl-graph                       # hint for generating a single etl graph"
	@echo "  make mapping-graph                   # hint for generating a single mapping graph"
	@echo "  make import-sql-dev                  # start import-sql /bin/bash terminal"
	@echo "  make import-osm-dev                  # start import-osm /bin/bash terminal (imposm3)"
	@echo "  make clean-docker                    # remove docker containers, PG data volume"
	@echo "  make forced-clean-sql                # drop all PostgreSQL tables for clean environment"
	@echo "  make docker-unnecessary-clean        # clean unnecessary docker image(s) and container(s)"
	@echo "  make refresh-docker-images           # refresh openmaptiles docker images from Docker HUB"
	@echo "  make remove-docker-images            # remove openmaptiles docker images"
	@echo "  make pgclimb-list-views              # list PostgreSQL public schema views"
	@echo "  make pgclimb-list-tables             # list PostgreSQL public schema tables"
	@echo "  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM information"
	@echo "  cat  quickstart.log                  # backup of the last ./quickstart.sh"
	@echo "  make help                            # help about available commands"
	@echo "=============================================================================="

.PHONY: build
build:
	mkdir -p build

build/openmaptiles.tm2source/data.yml: build
	mkdir -p build/openmaptiles.tm2source
	docker-compose run $(DC_OPTS) openmaptiles-tools generate-tm2source openmaptiles.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > build/openmaptiles.tm2source/data.yml

build/mapping.yaml: build
	docker-compose run $(DC_OPTS) openmaptiles-tools generate-imposm3 openmaptiles.yaml > build/mapping.yaml

build/tileset.sql: build
	docker-compose run $(DC_OPTS) openmaptiles-tools generate-sql openmaptiles.yaml > build/tileset.sql

.PHONY: clean
clean:
	rm -f build/openmaptiles.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql

.PHONY: clean-docker
clean-docker:
	docker-compose down -v --remove-orphans
	docker-compose rm -fv
	docker volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true

.PHONY: start-db-nowait
start-db-nowait: init-dirs
	@echo "Starting postgres docker compose target using $${POSTGIS_IMAGE:-default} image (no recreate if exists)" && \
	$(DOCKER_COMPOSE) up --no-recreate -d postgres

.PHONY: start-db
start-db: start-db-nowait
	@echo "Wait for PostgreSQL to start..."
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools pgwait

# Wrap start-db target but use the preloaded image
.PHONY: start-db-preloaded
start-db-preloaded: export POSTGIS_IMAGE=openmaptiles/postgis-preloaded
start-db-preloaded: export COMPOSE_HTTP_TIMEOUT=180
start-db-preloaded: start-db

.PHONY: stop-db
stop-db:
	@echo "Stopping PostgreSQL..."
	$(DOCKER_COMPOSE) stop postgres

.PHONY: list-geofabrik
list-geofabrik: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools download-osm list geofabrik

.PHONY: download-geofabrik
download-geofabrik:
	@echo ===============  download-geofabrik =======================
	@echo Download area :   $(area)
	@echo [[ example: make download-geofabrik  area=albania ]]
	@echo [[ list areas:  make download-geofabrik-list       ]]
	docker-compose run $(DC_OPTS) import-osm  ./download-geofabrik.sh $(area)
	ls -la ./data/$(area).*
	@echo "Generated config file: ./data/docker-compose-config.yml"
	@echo " "
	cat ./data/docker-compose-config.yml
	@echo " "

.PHONY: psql
psql: start-db-nowait
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c 'pgwait && psql.sh'

# Special cache handling for Docker Toolbox on Windows
ifeq ($(MSYSTEM),MINGW64)
  DC_CONFIG_CACHE := -f docker-compose.yml -f docker-compose-$(MSYSTEM).yml
  DC_OPTS_CACHE := $(strip $(filter-out --user=%,$(DC_OPTS)))
else
  DC_OPTS_CACHE := $(DC_OPTS)
endif

.PHONY: import-osm
import-osm: all start-db-nowait
	@$(assert_area_is_given)
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) openmaptiles-tools sh -c 'pgwait && import-osm $(PBF_FILE)'

.PHONY: update-osm
update-osm: all start-db-nowait
	@$(assert_area_is_given)
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) openmaptiles-tools sh -c 'pgwait && import-update'

.PHONY: import-diff
import-diff: all start-db-nowait
	@$(assert_area_is_given)
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) openmaptiles-tools sh -c 'pgwait && import-diff'

.PHONY: import-data
import-data: start-db
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) import-data

.PHONY: import-sql
import-sql: all start-db-nowait
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c 'pgwait && import-sql' | \
    	awk -v s=": WARNING:" '1{print; fflush()} $$0~s{print "\n*** WARNING detected, aborting"; exit(1)}' | \
    	awk '1{print; fflush()} $$0~".*ERROR" {txt=$$0} END{ if(txt){print "\n*** ERROR detected, aborting:"; print txt; exit(1)} }'

.PHONY: generate-tiles
generate-tiles: all start-db
	@echo "WARNING: This Mapnik-based method of tile generation is obsolete. Use generate-tiles-pg instead."
	@echo "Generating tiles into $(MBTILES_LOCAL_FILE) (will delete if already exists)..."
	@rm -rf "$(MBTILES_LOCAL_FILE)"
	$(DOCKER_COMPOSE) run $(DC_OPTS) generate-vectortiles
	@echo "Updating generated tile metadata ..."
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools \
			mbtiles-tools meta-generate "$(MBTILES_LOCAL_FILE)" $(TILESET_FILE) --auto-minmax --show-ranges

.PHONY: generate-tiles-pg
generate-tiles-pg: all start-db
	@echo "Generating tiles into $(MBTILES_LOCAL_FILE) (will delete if already exists) using PostGIS ST_MVT()..."
	@rm -rf "$(MBTILES_LOCAL_FILE)"
# For some reason Ctrl+C doesn't work here without the -T. Must be pressed twice to stop.
	$(DOCKER_COMPOSE) run -T $(DC_OPTS) openmaptiles-tools generate-tiles
	@echo "Updating generated tile metadata ..."
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools \
			mbtiles-tools meta-generate "$(MBTILES_LOCAL_FILE)" $(TILESET_FILE) --auto-minmax --show-ranges

.PHONY: start-tileserver
start-tileserver: init-dirs
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Download/refresh maptiler/tileserver-gl docker image"
	@echo "* see documentation: https://github.com/maptiler/tileserver-gl"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker pull maptiler/tileserver-gl
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Start maptiler/tileserver-gl "
	@echo "*       ----------------------------> check $(OMT_HOST):$(TPORT) "
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker run $(DC_OPTS) -it --name tileserver-gl -v $$(pwd)/data:/data -p $(TPORT):$(TPORT) maptiler/tileserver-gl --port $(TPORT)

.PHONY: start-postserve
start-postserve: start-db
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Bring up postserve at $(OMT_HOST):$(PPORT)"
	@echo "*     --> can view it locally (use make start-maputnik)"
	@echo "*     --> or can use https://maputnik.github.io/editor"
	@echo "* "
	@echo "*  set data source / TileJSON URL to $(OMT_HOST):$(PPORT)"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	$(DOCKER_COMPOSE) up -d postserve

.PHONY: stop-postserve
stop-postserve:
	$(DOCKER_COMPOSE) stop postserve

.PHONY: start-maputnik
start-maputnik: stop-maputnik start-postserve
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Start maputnik/editor "
	@echo "*       ---> go to $(OMT_HOST):8088 "
	@echo "*       ---> set data source / TileJSON URL to $(OMT_HOST):$(PPORT)"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker run $(DC_OPTS) --name maputnik_editor -d -p 8088:8888 maputnik/editor

.PHONY: stop-maputnik
stop-maputnik:
	-docker rm -f maputnik_editor

# STAT_FUNCTION=frequency|toplength|variance
.PHONY: generate-qa
generate-qa: all start-db-nowait
	@echo " "
	@echo "e.g. make generate-qa STAT_FUNCTION=frequency LAYER=transportation ATTRIBUTE=class"
	@echo " "
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools \
		layer-stats $(STAT_FUNCTION) $(TILESET_FILE) $(LAYER) $(ATTRIBUTE) -m 0 -n 14 -v

# generate all etl and mapping graphs
.PHONY: generate-devdoc
generate-devdoc: init-dirs
	mkdir -p ./build/devdoc && \
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c \
			'generate-etlgraph $(TILESET_FILE) $(GRAPH_PARAMS) && \
			 generate-mapping-graph $(TILESET_FILE) $(GRAPH_PARAMS)'

.PHONY: bash
bash: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools bash

.PHONY: import-wikidata
import-wikidata: init-dirs
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) openmaptiles-tools import-wikidata --cache /cache/wikidata-cache.json $(TILESET_FILE)

.PHONY: reset-db-stats
reset-db-stats: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'SELECT pg_stat_statements_reset();'

.PHONY: list-views
list-views: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -A -F"," -P pager=off -P footer=off \
		-c "select viewname from pg_views where schemaname='public' order by viewname;"

.PHONY: list-tables
list-tables: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -A -F"," -P pager=off -P footer=off \
		-c "select tablename from pg_tables where schemaname='public' order by tablename;"

.PHONY: psql-list-tables
psql-list-tables: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c "\d+"

.PHONY: vacuum-db
vacuum-db: init-dirs
	@echo "Start - postgresql: VACUUM ANALYZE VERBOSE;"
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'VACUUM ANALYZE VERBOSE;'

.PHONY: analyze-db
analyze-db: init-dirs
	@echo "Start - postgresql: ANALYZE VERBOSE;"
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'ANALYZE VERBOSE;'

.PHONY: list-docker-images
list-docker-images:
	docker images | grep openmaptiles

.PHONY: refresh-docker-images
refresh-docker-images: init-dirs
ifneq ($(strip $(NO_REFRESH)),)
	@echo "Skipping docker image refresh"
else
	@echo ""
	@echo "Refreshing docker images... Use NO_REFRESH=1 to skip."
ifneq ($(strip $(USE_PRELOADED_IMAGE)),)
	POSTGIS_IMAGE=openmaptiles/postgis-preloaded \
		docker-compose pull --ignore-pull-failures $(QUIET_FLAG) openmaptiles-tools generate-vectortiles postgres
else
	docker-compose pull --ignore-pull-failures $(QUIET_FLAG) openmaptiles-tools generate-vectortiles postgres import-data
endif
endif

.PHONY: remove-docker-images
remove-docker-images:
	@echo "Deleting all openmaptiles related docker image(s)..."
	@$(DOCKER_COMPOSE) down
	@docker images "openmaptiles/*" -q                | $(XARGS) docker rmi -f
	@docker images "maputnik/editor" -q               | $(XARGS) docker rmi -f
	@docker images "maptiler/tileserver-gl" -q        | $(XARGS) docker rmi -f

.PHONY: clean-unnecessary-docker
clean-unnecessary-docker:
	@echo "Deleting unnecessary container(s)..."
	@docker ps -a -q --filter "status=exited" | $(XARGS) docker rm
	@echo "Deleting unnecessary image(s)..."
	@docker images | awk -F" " '/<none>/{print $$3}' | $(XARGS) docker rmi

.PHONY: test-perf-null
test-perf-null: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools test-perf $(TILESET_FILE) --test null --no-color

.PHONY: build-test-pbf
build-test-pbf: init-dirs
	docker-compose run $(DC_OPTS) openmaptiles-tools /tileset/.github/workflows/build-test-data.sh

.PHONY: debug
debug:  ## Use this target when developing Makefile itself to verify loaded environment variables
	@$(assert_area_is_given)
	@echo file_exists = $(wildcard $(AREA_BBOX_FILE))
	@echo AREA_BBOX_FILE = $(AREA_BBOX_FILE) , $$AREA_ENV_FILE
	@echo BBOX = $(BBOX) , $$BBOX
	@echo MIN_ZOOM = $(MIN_ZOOM) , $$MIN_ZOOM
	@echo MAX_ZOOM = $(MAX_ZOOM) , $$MAX_ZOOM

build/import-tests.osm.pbf: init-dirs
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) openmaptiles-tools sh -c 'osmconvert tests/import/*.osm -o=build/import-tests.osm.pbf'

data/changes.state.txt:
	cp -f tests/changes.state.txt data/

data/last.state.txt:
	cp -f tests/last.state.txt data/

data/changes.repl.json:
	cp -f tests/changes.repl.json data/

data/changes.osc.gz: init-dirs
	@echo " UPDATE unit test data..."
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) openmaptiles-tools sh -c 'osmconvert tests/update/*.osc --merge-versions -o=data/changes.osc && gzip -f data/changes.osc'

test-sql: clean refresh-docker-images destroy-db start-db-nowait build/import-tests.osm.pbf data/changes.state.txt data/last.state.txt data/changes.repl.json build/mapping.yaml data/changes.osc.gz build/openmaptiles.tm2source/data.yml build/mapping.yaml build-sql
	$(eval area := changes)

	@echo "Load IMPORT test data"
	sed -ir "s/^[#]*\s*MAX_ZOOM=.*/MAX_ZOOM=14/" .env
	sed -ir "s/^[#]*\s*DIFF_MODE=.*/DIFF_MODE=false/" .env
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) openmaptiles-tools sh -c 'pgwait && import-osm build/import-tests.osm.pbf'
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) import-data

	@echo "Apply OpenMapTiles SQL schema to test data @ Zoom 14..."
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c 'pgwait && import-sql' | \
    	awk -v s=": WARNING:" '1{print; fflush()} $$0~s{print "\n*** WARNING detected, aborting"; exit(1)}' | \
    	awk '1{print; fflush()} $$0~".*ERROR" {txt=$$0} END{ if(txt){print "\n*** ERROR detected, aborting:"; print txt; exit(1)} }'

	@echo "Test SQL output for Import Test Data"
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) openmaptiles-tools sh -c 'pgwait && psql.sh < tests/test-post-import.sql'

	@echo "Run UPDATE process on test data..."
	sed -ir "s/^[#]*\s*DIFF_MODE=.*/DIFF_MODE=true/" .env
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) openmaptiles-tools sh -c 'pgwait && import-diff'

	@echo "Test SQL output for Update Test Data"
	$(DOCKER_COMPOSE) $(DC_CONFIG_CACHE) run $(DC_OPTS_CACHE) openmaptiles-tools sh -c 'pgwait && psql.sh < tests/test-post-update.sql'

qwant:
	./generate_qwant.sh