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
  # create images in ./build/devdoc and compare them to ./layers
  GRAPH_PARAMS=./build/devdoc ./layers
else
  # update graphs in the ./layers dir
  GRAPH_PARAMS=./layers
endif

# Set OpenMapTiles host
OMT_HOST := http://$(firstword $(subst :, ,$(subst tcp://,,$(DOCKER_HOST))) localhost)
export OMT_HOST

# This defines an easy $(newline) value to act as a "\n". Make sure to keep exactly two empty lines after newline.
define newline


endef

# use the old postgres connection values if they are existing
PGHOST := $(or $(POSTGRES_HOST),$(PGHOST))
PGPORT := $(or $(POSTGRES_PORT),$(PGPORT))
PGDATABASE := $(or $(POSTGRES_DB),$(PGDATABASE))
PGUSER := $(or $(POSTGRES_USER),$(PGUSER))
PGPASSWORD := $(or $(POSTGRES_PASSWORD),$(PGPASSWORD))

#
# Determine area to work on
# If $(area) parameter is not set, and only one *.osm.pbf file is found in ./data, use it as $(area).
# Otherwise, all make targets requiring an area will show an error.
# Note: If no *.osm.pbf files are found, once the users call  "make download area=..."
#       they will not need to use an "area=" parameter again because there will be just a single file.
#

# historically we have been using $(area) rather than $(AREA), so make both work
area ?= $(AREA)
# Ensure the $(area) param is set, or try to automatically determine it based on available data files
ifeq ($(strip $(area)),)
  # An $(area) parameter is not set. If only one *.osm.pbf file is found in ./data, use it as $(area).
  data_files := $(shell find data -name '*.osm.pbf' 2>/dev/null)
  ifneq ($(word 2,$(data_files)),)
    define assert_area_is_given
	  @echo ""
	  @echo "ERROR: The 'area' parameter or environment variable have not been set, and there several 'area' options:"
	  @$(patsubst data/%.osm.pbf,echo "  '%'";,$(data_files))
	  @echo ""
	  @echo "To specify an area use:"
	  @echo "  make $@ area=<area-id>"
	  @echo ""
	  @exit 1
    endef
  else
    ifeq ($(word 1,$(data_files)),)
      define assert_area_is_given
        @echo ""
        @echo "ERROR: The 'area' parameter (or env var) has not been set, and there are no data/*.osm.pbf files"
        @echo ""
        @echo "To specify an area use"
        @echo "  make $@ area=<area-id>"
        @echo ""
        @echo "To download an area, use   make download area=<area-id>"
        @echo "To list downloadable areas, use   make list-geofabrik   and/or   make list-bbbike"
        @exit 1
        @echo ""
      endef
    else
      # Keep just the name of the data file, without the .osm.pbf extension
      area := $(patsubst data/%.osm.pbf,%,$(data_files))
      # Rename area-latest.osm.pbf to area.osm.pbf
      # TODO: This if statement could be removed in a few months once everyone is using the file without the `-latest`?
      ifneq ($(area),$(area:-latest=))
        $(shell mv "data/$(area).osm.pbf" "data/$(area:-latest=).osm.pbf")
        area := $(area:-latest=)
        $(warning ATTENTION: File data/$(area)-latest.osm.pbf was renamed to $(area).osm.pbf.)
        AREA_INFO := Detected area=$(area) based on finding a 'data/$(area)-latest.osm.pbf' file - renamed to '$(area).osm.pbf'. Use 'area' parameter or environment variable to override.
      else
        AREA_INFO := Detected area=$(area) based on finding a 'data/$(area).osm.pbf' file. Use 'area' parameter or environment variable to override.
      endif
    endif
  endif
endif

ifneq ($(strip $(AREA_INFO)),)
  define assert_area_is_given
      @echo "$(AREA_INFO)"
  endef
endif

# If set, this file will be downloaded in download-osm and imported in the import-osm targets
PBF_FILE ?= data/$(area).osm.pbf

# For download-osm, allow URL parameter to download file from a given URL. Area param must still be provided.
ifneq ($(strip $(url)),)
  DOWNLOAD_AREA := $(url)
else
  DOWNLOAD_AREA := $(area)
endif

# import-borders uses these temp files during border parsing/import
export BORDERS_CLEANUP_FILE ?= data/borders/$(area).cleanup.pbf
export BORDERS_PBF_FILE ?= data/borders/$(area).filtered.pbf
export BORDERS_CSV_FILE ?= data/borders/$(area).lines.csv

# The file is placed into the $EXPORT_DIR=/export (mapped to ./data)
export MBTILES_FILE ?= $(area).mbtiles
MBTILES_LOCAL_FILE = data/$(MBTILES_FILE)

ifeq ($(strip $(DIFF_MODE)),true)
  # import-osm implementation requires IMPOSM_CONFIG_FILE to be set to a valid file
  # For static (no-updates) import, we don't need to override the default value
  # For the update mode, set location of the dynamically-generated area-based config file
  export IMPOSM_CONFIG_FILE = data/$(area).repl.json
endif

# Load area-specific bbox file that gets generated by the download-osm --bbox
AREA_BBOX_FILE ?= data/$(area).bbox
ifneq (,$(wildcard $(AREA_BBOX_FILE)))
  cat := $(if $(filter $(OS),Windows_NT),type,cat)
  BBOX := $(shell $(cat) ${AREA_BBOX_FILE})
  export BBOX
endif

define HELP_MESSAGE
==============================================================================
 OpenMapTiles  https://github.com/openmaptiles/openmaptiles

Hints for testing areas
  make list-geofabrik                  # list actual geofabrik OSM extracts for download -> <<your-area>>
  ./quickstart.sh <<your-area>>        # example:  ./quickstart.sh madagascar

Hints for designers:
  make start-maputnik                  # start Maputnik Editor + dynamic tile server [ see $(OMT_HOST):8088 ]
  make start-postserve                 # start dynamic tile server                   [ see $(OMT_HOST):$(PPORT) ]
  make stop-postserve                  # stop dynamic tile server
  make start-tileserver                # start maptiler/tileserver-gl                [ see $(OMT_HOST):$(TPORT) ]

Hints for developers:
  make                                 # build source code
  make bash                            # start openmaptiles-tools /bin/bash terminal
  make generate-bbox-file              # compute bounding box of a data file and store it in a file
  make generate-devdoc                 # generate devdoc including graphs for all layers [./layers/...]
  make generate-qa                     # statistics for a given layer's field
  make generate-tiles-pg               # generate vector tiles based on .env settings using PostGIS ST_MVT()
  make generate-tiles                  # generate vector tiles based on .env settings using Mapnik (obsolete)
  cat  .env                            # list PG database and MIN_ZOOM and MAX_ZOOM information
  cat  quickstart.log                  # transcript of the last ./quickstart.sh run
  make help                            # help about available commands

Hints for downloading & importing data:
  make list-geofabrik                  # list actual geofabrik OSM extracts for download
  make list-bbbike                     # list actual BBBike OSM extracts for download
  make download area=albania           # download OSM data from any source       and create config file
  make download-geofabrik area=albania # download OSM data from geofabrik.de     and create config file
  make download-osmfr area=asia/qatar  # download OSM data from openstreetmap.fr and create config file
  make download-bbbike area=Amsterdam  # download OSM data from bbbike.org       and create config file
  make import-data                     # Import data from OpenStreetMapData, Natural Earth and OSM Lake Labels.
  make import-osm                      # Import OSM data with the mapping rules from build/mapping.yaml
  make import-borders                  # Create borders table using extra processing with osmborder tool
  make import-wikidata                 # Import labels from Wikidata
  make import-sql                      # Import layers (run this after modifying layer SQL)

Hints for database management:
  make psql                            # start PostgreSQL console
  make psql-list-tables                # list all PostgreSQL tables
  make list-views                      # list PostgreSQL public schema views
  make list-tables                     # list PostgreSQL public schema tables
  make vacuum-db                       # PostgreSQL: VACUUM ANALYZE
  make analyze-db                      # PostgreSQL: ANALYZE
  make destroy-db                      # remove docker containers and PostgreSQL data volume
  make start-db                        # start PostgreSQL, creating it if it doesn't exist
  make start-db-preloaded              # start PostgreSQL, creating data-prepopulated one if it doesn't exist
  make stop-db                         # stop PostgreSQL database without destroying the data

Hints for Docker management:
  make clean-unnecessary-docker        # clean unnecessary docker image(s) and container(s)
  make refresh-docker-images           # refresh openmaptiles docker images from Docker HUB
  make remove-docker-images            # remove openmaptiles docker images
  make list-docker-images              # show a list of available docker images
==============================================================================
endef
export HELP_MESSAGE

#
#  TARGETS
#

.PHONY: all
all: init-dirs build/openmaptiles.tm2source/data.yml build/mapping.yaml build-sql

.PHONY: help
help:
	@echo "$$HELP_MESSAGE" | less

define win_fs_error
	( \
	echo "" ;\
	echo "ERROR: Windows native filesystem" ;\
	echo "" ;\
	echo "Please avoid running OpenMapTiles in a Windows filesystem." ;\
	echo "See https://github.com/openmaptiles/openmaptiles/issues/1095#issuecomment-817095465" ;\
	echo "" ;\
	exit 1 ;\
	)
endef

.PHONY: init-dirs
init-dirs:
	@mkdir -p build/sql/parallel
	@mkdir -p build/openmaptiles.tm2source
	@mkdir -p data/borders
	@mkdir -p cache
	@ ! ($(DOCKER_COMPOSE) 2>/dev/null run $(DC_OPTS) openmaptiles-tools df --output=fstype /tileset| grep -q 9p) || ($(win_fs_error))

build/openmaptiles.tm2source/data.yml: init-dirs
ifeq (,$(wildcard build/openmaptiles.tm2source/data.yml))
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools generate-tm2source $(TILESET_FILE) --host="$(PGHOST)" --port=$(PGPORT) --database="$(PGDATABASE)" --user="$(PGUSER)" --password="$(PGPASSWORD)" > $@
endif

build/mapping.yaml: init-dirs
ifeq (,$(wildcard build/mapping.yaml))
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools generate-imposm3 $(TILESET_FILE) > $@
endif

.PHONY: build-sql
build-sql: init-dirs
ifeq (,$(wildcard build/sql/run_last.sql))
	@mkdir -p build/sql/parallel
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools bash -c \
		'generate-sql $(TILESET_FILE) --dir ./build/sql \
		&& generate-sqltomvt $(TILESET_FILE) \
							 --key --gzip --postgis-ver 3.0.1 \
							 --function --fname=getmvt >> ./build/sql/run_last.sql'
endif

.PHONY: clean
clean:
	rm -rf build

.PHONY: destroy-db
# TODO:  Use https://stackoverflow.com/a/27852388/177275
destroy-db: DC_PROJECT := $(shell echo $(DC_PROJECT) | tr A-Z a-z)
destroy-db:
	$(DOCKER_COMPOSE) down -v --remove-orphans
	$(DOCKER_COMPOSE) rm -fv
	docker volume ls -q -f "name=^$(DC_PROJECT)_" | $(XARGS) docker volume rm
	rm -rf cache

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

.PHONY: list-bbbike
list-bbbike: init-dirs
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools download-osm list bbbike

#
# download, download-geofabrik, download-osmfr, and download-bbbike are handled here
# The --imposm-cfg will fail for some of the sources, but we ignore that error -- only needed for diff mode
#
OSM_SERVERS := geofabrik osmfr bbbike
ALL_DOWNLOADS := $(addprefix download-,$(OSM_SERVERS)) download
OSM_SERVER=$(patsubst download,,$(patsubst download-%,%,$@))
.PHONY: $(ALL_DOWNLOADS)
$(ALL_DOWNLOADS): init-dirs
	@$(assert_area_is_given)
ifneq ($(strip $(url)),)
	$(if $(OSM_SERVER),$(error url parameter can only be used with non-specific download target:$(newline)       make download area=$(area) url="$(url)"$(newline)))
endif
ifeq (,$(wildcard $(PBF_FILE)))
 ifeq ($(strip $(DIFF_MODE)),true)
	@echo "Downloading $(DOWNLOAD_AREA) with replication support into $(PBF_FILE) and $(IMPOSM_CONFIG_FILE) from $(if $(OSM_SERVER),$(OSM_SERVER),any source)"
	@$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools download-osm $(OSM_SERVER) "$(DOWNLOAD_AREA)" \
				--imposm-cfg "$(IMPOSM_CONFIG_FILE)" \
				--bbox "$(AREA_BBOX_FILE)" \
				--output "$(PBF_FILE)"
 else
	@echo "Downloading $(DOWNLOAD_AREA) into $(PBF_FILE) from $(if $(OSM_SERVER),$(OSM_SERVER),any source)"
	@$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools download-osm $(OSM_SERVER) "$(DOWNLOAD_AREA)" \
				--bbox "$(AREA_BBOX_FILE)" \
				--output "$(PBF_FILE)"
 endif
	@echo ""
else
 ifeq ($(strip $(DIFF_MODE)),true)
  ifeq (,$(wildcard $(IMPOSM_CONFIG_FILE)))
	$(error \
		$(newline)   Data files $(PBF_FILE) already exists, but $(IMPOSM_CONFIG_FILE) does not. \
		$(newline)   You probably downloaded the data file before setting DIFF_MODE=true. \
		$(newline)   You can delete the data file  $(PBF_FILE) and re-run  make download \
		$(newline)   to re-download and generate config, or manually create  $(IMPOSM_CONFIG_FILE) \
		$(newline)   See example    https://github.com/openmaptiles/openmaptiles-tools/blob/v5.2/bin/config/repl_config.json \
		$(newline))
  else
	@echo "Data files $(PBF_FILE) and replication config $(IMPOSM_CONFIG_FILE) already exists, skipping the download."
  endif
 else
	@echo "Data files $(PBF_FILE) already exists, skipping the download."
 endif
endif

.PHONY: generate-bbox-file
generate-bbox-file:
	@$(assert_area_is_given)
ifeq (,$(wildcard $(AREA_BBOX_FILE)))
	@$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools download-osm bbox "$(PBF_FILE)" "$(AREA_BBOX_FILE)"
else
	@echo "Configuration file $(AREA_BBOX_FILE) already exists, no need to regenerate.  BBOX=$(BBOX)"
endif

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

.PHONY: import-borders
import-borders: start-db-nowait
ifeq (,$(wildcard $(BORDERS_CSV_FILE)))
	@$(assert_area_is_given)
	@echo "Generating borders out of $(PBF_FILE)"
else
	@echo "Borders already exists. Useing $(BORDERS_CSV_FILE) to import borders"
endif
	$(DOCKER_COMPOSE) run $(DC_OPTS) openmaptiles-tools sh -c \
		'pgwait && import-borders $$([ -f "$(BORDERS_CSV_FILE)" ] && echo load $(BORDERS_CSV_FILE) || echo import $(PBF_FILE))'

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
