# Options to run with docker and docker-compose - ensure the container is destroyed on exit
# Containers run as the current user rather than root (so that created files are not root-owned)
DC_OPTS?=--rm -u $(shell id -u):$(shell id -g)

# Allow a custom docker-compose project name
ifeq ($(strip $(DC_PROJECT)),)
  override DC_PROJECT:=$(notdir $(shell pwd))
  DOCKER_COMPOSE:= docker-compose
else
  DOCKER_COMPOSE:= docker-compose --project-name $(DC_PROJECT)
endif

# Use `xargs --no-run-if-empty` flag, if supported
XARGS:=xargs $(shell xargs --no-run-if-empty </dev/null 2>/dev/null && echo --no-run-if-empty)

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

# Set OpenMapTiles host
OMT_HOST:=http://$(firstword $(subst :, ,$(subst tcp://,,$(DOCKER_HOST))) localhost)

.PHONY: help
help:
	@echo "=============================================================================="
	@echo " OpenMapTiles  https://github.com/openmaptiles/openmaptiles "
	@echo "Hints for testing areas                "
	@echo "  make list-geofabrik                  # list actual geofabrik OSM extracts for download -> <<your-area>> "
	@echo "  ./quickstart.sh <<your-area>>        # example:  ./quickstart.sh madagascar "
	@echo " "
	@echo "Hints for designers:"
	@echo "  make maputnik-start                  # start Maputnik Editor + dynamic tile server [ see $(OMT_HOST):8088 ]"
	@echo "  make postserve-start                 # start dynamic tile server [ see $(OMT_HOST):8088 ]"
	@echo "  make tileserver-start                # start klokantech/tileserver-gl     [ see $(OMT_HOST):8080 ]"
	@echo " "
	@echo "Hints for developers:"
	@echo "  make                                 # build source code"
	@echo "  make list-geofabrik                  # list actual geofabrik OSM extracts for download"
	@echo "  make download-geofabrik area=albania # download OSM data from geofabrik,        and create config file"
	@echo "  make download-osmfr area=asia/qatar  # download OSM data from openstreetmap.fr, and create config file"
	@echo "  make download-bbike area=Amsterdam   # download OSM data from bbike.org,        and create config file"
	@echo "  make psql                            # start PostgreSQL console"
	@echo "  make psql-list-tables                # list all PostgreSQL tables"
	@echo "  make psql-vacuum-analyze             # PostgreSQL: VACUUM ANALYZE"
	@echo "  make psql-analyze                    # PostgreSQL: ANALYZE"
	@echo "  make generate-qareports              # generate reports                                [./build/qareports]"
	@echo "  make generate-devdoc                 # generate devdoc including graphs for all layers [./layers/...]"
	@echo "  make tools-dev                       # start openmaptiles-tools /bin/bash terminal"
	@echo "  make db-destroy                      # remove docker containers and PostgreSQL data volume"
	@echo "  make db-start                        # start PostgreSQL, creating it if it doesn't exist"
	@echo "  make db-stop                         # stop PostgreSQL database without destroying the data"
	@echo "  make import-sql-dev                  # start import-sql /bin/bash terminal"
	@echo "  make import-osm-dev                  # start import-osm /bin/bash terminal (imposm3)"
	@echo "  make docker-unnecessary-clean        # clean unnecessary docker image(s) and container(s)"
	@echo "  make refresh-docker-images           # refresh openmaptiles docker images from Docker HUB"
	@echo "  make remove-docker-images            # remove openmaptiles docker images"
	@echo "  make pgclimb-list-views              # list PostgreSQL public schema views"
	@echo "  make pgclimb-list-tables             # list PostgreSQL public schema tables"
	@echo "  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM information"
	@echo "  cat  quickstart.log                  # transcript of the last ./quickstart.sh run"
	@echo "  make help                            # help about available commands"
	@echo "=============================================================================="

.PHONY: init-dirs
init-dirs:
	@mkdir -p build
	@mkdir -p data
	@mkdir -p cache

build/openmaptiles.tm2source/data.yml: init-dirs
	mkdir -p build/openmaptiles.tm2source
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools generate-tm2source openmaptiles.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > $@

build/mapping.yaml: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools generate-imposm3 openmaptiles.yaml > $@

.PHONY: build-sql
build-sql: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools generate-sql openmaptiles.yaml > build/tileset.sql

.PHONY: clean
clean:
	rm -rf build

.PHONY: db-destroy
db-destroy: override DC_PROJECT:=$(shell echo $(DC_PROJECT) | tr A-Z a-z)
db-destroy:
	$(DOCKER_COMPOSE) down -v --remove-orphans
	$(DOCKER_COMPOSE) rm -fv
	docker volume ls -q -f "name=^$(DC_PROJECT)_" | $(XARGS) docker volume rm
	rm -rf cache

.PHONY: db-start
db-start:
	$(DOCKER_COMPOSE) up --no-recreate -d postgres
	@echo "Wait for PostgreSQL to start..."
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm ./pgwait.sh

.PHONY: db-stop
db-stop:
	@echo "Stopping PostgreSQL..."
	$(DOCKER_COMPOSE) stop postgres

.PHONY: list-geofabrik
list-geofabrik:
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools download-osm list geofabrik

OSM_SERVERS:=geofabrik osmfr bbbike
ALL_DOWNLOADS:=$(addprefix download-,$(OSM_SERVERS))
OSM_SERVER=$(patsubst download-%,%,$@)
.PHONY: $(ALL_DOWNLOADS)
$(ALL_DOWNLOADS): init-dirs
ifeq ($(strip $(area)),)
	@echo ""
	@echo "ERROR: Unable to download an area if area is not given."
	@echo "Usage:"
	@echo "  make download-$(OSM_SERVER) area=<area-id>"
	@echo ""
	$(if $(filter %-geofabrik,$@),@echo "Use   make list-geofabrik   to get a list of all available areas";echo "")
	@exit 1
else
	@echo "=============== download-$(OSM_SERVER) ======================="
	@echo "Download area: $(area)"
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools bash -c \
		'download-osm $(OSM_SERVER) $(area) \
			--minzoom $$QUICKSTART_MIN_ZOOM \
			--maxzoom $$QUICKSTART_MAX_ZOOM \
			--make-dc /import/docker-compose-config.yml -- -d /import'
	ls -la ./data/$(notdir $(area))*
	@echo ""
endif

.PHONY: psql
psql: db-start
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm ./psql.sh

.PHONY: import-osm
import-osm: db-start all
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm

.PHONY: import-osmsql
import-osmsql: db-start all import-osm import-sql

.PHONY: import-data
import-data: db-start
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-data

.PHONY: import-borders
import-borders: db-start
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools import-borders

.PHONY: import-sql
import-sql: db-start all
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools import-sql

.PHONY: generate-tiles
ifneq ($(wildcard data/docker-compose-config.yml),)
  DC_CONFIG_TILES:=-f docker-compose.yml -f ./data/docker-compose-config.yml
endif
generate-tiles: init-dirs db-start all
	rm -rf data/tiles.mbtiles
	echo "Generating tiles ..."; \
	$(DOCKER_COMPOSE) $(DC_CONFIG_TILES) run $(DC_OPTS) generate-vectortiles
	@echo "Updating generated tile metadata ..."
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools generate-metadata ./data/tiles.mbtiles

.PHONY: tileserver-start
tileserver-start: init-dirs
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
	@echo "*       ----------------------------> check $(OMT_HOST):8080 "
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker run $(DC_OPTS) -it --name tileserver-gl -v $$(pwd)/data:/data -p 8080:8080 klokantech/tileserver-gl --port 8080

.PHONY: postserve-start
postserve-start: db-start
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Bring up postserve at $(OMT_HOST):8090"
	@echo "*     --> can view it locally (use make maputnik-start)"
	@echo "*     --> or can use https://maputnik.github.io/editor"
	@echo "* "
	@echo "*  set data source / TileJSON URL to http://$(OMT_HOST):8090"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	$(DOCKER_COMPOSE) up -d postserve

.PHONY: postserve-stop
postserve-stop:
	$(DOCKER_COMPOSE) stop postserve

.PHONY: maputnik-start
maputnik-start: maputnik-stop postserve-start
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Start maputnik/editor "
	@echo "*       ---> go to http://$(OMT_HOST):8088 "
	@echo "*       ---> set data source / TileJSON URL to http://$(OMT_HOST):8090"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker run $(DC_OPTS) --name maputnik_editor -d -p 8088:8888 maputnik/editor

.PHONY: maputnik-stop
maputnik-stop:
	-docker rm -f maputnik_editor

.PHONY: generate-qareports
generate-qareports:
	./qa/run.sh

# generate all etl and mapping graphs
.PHONY: generate-devdoc
generate-devdoc: init-dirs
	mkdir -p ./build/devdoc && \
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c \
			'generate-etlgraph openmaptiles.yaml $(GRAPH_PARAMS) && \
			 generate-mapping-graph openmaptiles.yaml $(GRAPH_PARAMS)'

.PHONY: tools-dev
tools-dev:
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools bash

.PHONY: import-osm-dev
import-osm-dev:
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm /bin/bash

.PHONY: import-wikidata
import-wikidata:
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools import-wikidata --cache /cache/wikidata-cache.json openmaptiles.yaml

.PHONY: psql-pg-stat-reset
psql-pg-stat-reset:
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm ./psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'SELECT pg_stat_statements_reset();'

.PHONY: forced-clean-sql
forced-clean-sql:
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm ./psql.sh -v ON_ERROR_STOP=1 \
		-c "DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA IF NOT EXISTS public;" \
		-c "CREATE EXTENSION hstore; CREATE EXTENSION postgis; CREATE EXTENSION unaccent;" \
		-c "CREATE EXTENSION fuzzystrmatch; CREATE EXTENSION osml10n; CREATE EXTENSION pg_stat_statements;" \
		-c "GRANT ALL ON SCHEMA public TO public; COMMENT ON SCHEMA public IS 'standard public schema';"

.PHONY: list-views
list-views:
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm ./psql.sh -v ON_ERROR_STOP=1 -A -F"," -P pager=off -P footer=off \
		-c "select schemaname, viewname from pg_views where schemaname='public' order by viewname;"

.PHONY: list-tables
list-tables:
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm ./psql.sh -v ON_ERROR_STOP=1 -A -F"," -P pager=off -P footer=off \
		-c "select schemaname, tablename from pg_tables where schemaname='public' order by tablename;"

.PHONY: psql-list-tables
psql-list-tables:
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm ./psql.sh -v ON_ERROR_STOP=1 -P pager=off -c "\d+"

.PHONY: psql-vacuum-analyze
psql-vacuum-analyze:
	@echo "Start - postgresql: VACUUM ANALYZE VERBOSE;"
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm ./psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'VACUUM ANALYZE VERBOSE;'

.PHONY: psql-analyze
psql-analyze:
	@echo "Start - postgresql: ANALYZE VERBOSE;"
	$(DOCKER_COMPOSE) run $(DC_OPTS) import-osm ./psql.sh -v ON_ERROR_STOP=1 -P pager=off -c 'ANALYZE VERBOSE;'

.PHONY: list-docker-images
list-docker-images:
	docker images | grep openmaptiles

.PHONY: refresh-docker-images
refresh-docker-images:
ifneq ($(strip $(NO_REFRESH)),)
	@echo "Skipping docker image refresh"
else
	@echo ""
	@echo "Refreshing docker images... Use NO_REFRESH=1 to skip."
	$(DOCKER_COMPOSE) pull --ignore-pull-failures
endif

.PHONY: remove-docker-images
remove-docker-images:
	@echo "Deleting all openmaptiles related docker image(s)..."
	@$(DOCKER_COMPOSE) down
	@docker images "openmaptiles/*" -q                | $(XARGS) docker rmi -f
	@docker images "maputnik/editor" -q               | $(XARGS) docker rmi -f
	@docker images "klokantech/tileserver-gl" -q      | $(XARGS) docker rmi -f

.PHONY: docker-unnecessary-clean
docker-unnecessary-clean:
	@echo "Deleting unnecessary container(s)..."
	@docker ps -a --filter "status=exited" | $(XARGS) docker rm
	@echo "Deleting unnecessary image(s)..."
	@docker images | grep \<none\> | awk -F" " '{print $$3}' | $(XARGS) docker rmi

.PHONY: test-perf-null
test-perf-null:
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools test-perf openmaptiles.yaml --test null --no-color
