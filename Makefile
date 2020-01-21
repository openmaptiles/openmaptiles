# Options to run with docker and docker-compose - ensure the container is destroyed on exit
DC_OPTS?=--rm

# container runs as the current user rather than root (so that created files are not root-owned)
DC_USER_OPTS?=$(DC_OPTS) -u $$(id -u $${USER}):$$(id -g $${USER})

# If running in the test mode, compare files rather than copy them
TEST_MODE?=no
ifeq ($(TEST_MODE),yes)
  COPY_TO_GIT=diff
else
  COPY_TO_GIT=cp
endif

.PHONY: all
all: build/openmaptiles.tm2source/data.yml build/mapping.yaml build/tileset.sql

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
	docker-compose run $(DC_OPTS) openmaptiles-tools generate-tm2source openmaptiles.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > $@

build/mapping.yaml: build
	docker-compose run $(DC_OPTS) openmaptiles-tools generate-imposm3 openmaptiles.yaml > $@

build/tileset.sql: build
	docker-compose run $(DC_OPTS) openmaptiles-tools generate-sql openmaptiles.yaml > $@

.PHONY: clean
clean:
	rm -f build/openmaptiles.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql

.PHONY: clean-docker
clean-docker:
	docker-compose down -v --remove-orphans
	docker-compose rm -fv
	docker volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true

.PHONY: db-start
db-start:
	docker-compose up -d postgres
	@echo "Wait for PostgreSQL to start..."
	docker-compose run $(DC_OPTS) import-osm  ./pgwait.sh

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
psql: db-start
	docker-compose run $(DC_OPTS) import-osm ./psql.sh

.PHONY: import-osm
import-osm: db-start all
	docker-compose run $(DC_OPTS) import-osm

.PHONY: import-sql
import-sql: db-start all
	docker-compose run $(DC_OPTS) openmaptiles-tools import-sql

.PHONY: import-osmsql
import-osmsql: db-start all
	docker-compose run $(DC_OPTS) import-osm
	docker-compose run $(DC_OPTS) openmaptiles-tools import-sql

.PHONY: generate-tiles
generate-tiles: db-start all
	rm -rf data/tiles.mbtiles
	if [ -f ./data/docker-compose-config.yml ]; then \
		docker-compose -f docker-compose.yml -f ./data/docker-compose-config.yml run $(DC_OPTS) generate-vectortiles; \
	else \
		docker-compose run $(DC_OPTS) generate-vectortiles; \
	fi
	docker-compose run $(DC_OPTS) openmaptiles-tools  generate-metadata ./data/tiles.mbtiles
	docker-compose run $(DC_OPTS) openmaptiles-tools  chmod 666         ./data/tiles.mbtiles

.PHONY: start-tileserver
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
	docker run $(DC_OPTS) -it --name tileserver-gl -v $$(pwd)/data:/data -p 8080:80 klokantech/tileserver-gl

.PHONY: start-postserve
start-postserve: db-start
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Bring up postserve at localhost:8090"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker-compose up -d postserve
	docker pull maputnik/editor
	@echo " "
	@echo "***********************************************************"
	@echo "* "
	@echo "* Start maputnik/editor "
	@echo "*       ---> go to http://localhost:8088"
	@echo "*       ---> set 'data source' to  http://localhost:8090"
	@echo "* "
	@echo "***********************************************************"
	@echo " "
	docker rm -f maputnik_editor || true
	docker run $(DC_OPTS) --name maputnik_editor -d -p 8088:8888 maputnik/editor

.PHONY: generate-qareports
generate-qareports:
	./qa/run.sh

build/devdoc:
	mkdir -p ./build/devdoc


layers = $(notdir $(wildcard layers/*)) # all layers

.PHONY: etl-graph
etl-graph:
	@echo 'Use'
	@echo '   make etl-graph-[layer]	to generate etl graph for [layer]'
	@echo '   example: make etl-graph-poi'
	@echo 'Valid layers: $(layers)'

# generate etl graph for a certain layer, e.g. etl-graph-building, etl-graph-place
etl-graph-%: layers/% build/devdoc
	docker-compose run $(DC_USER_OPTS) openmaptiles-tools generate-etlgraph layers/$*/$*.yaml ./build/devdoc
	@$(COPY_TO_GIT) ./build/devdoc/etl_$*.png layers/$*/etl_diagram.png


mappingLayers = $(notdir $(patsubst %/mapping.yaml,%, $(wildcard layers/*/mapping.yaml))) # layers with mapping.yaml

# generate mapping graph for a certain layer, e.g. mapping-graph-building, mapping-graph-place
.PHONY: mapping-graph
mapping-graph:
	@echo 'Use'
	@echo '   make mapping-graph-[layer]	to generate mapping graph for [layer]'
	@echo '   example: make mapping-graph-poi'
	@echo 'Valid layers: $(mappingLayers)'

mapping-graph-%: ./layers/%/mapping.yaml build/devdoc
	docker-compose run $(DC_USER_OPTS) openmaptiles-tools generate-mapping-graph layers/$*/$*.yaml ./build/devdoc/mapping-diagram-$*
	@$(COPY_TO_GIT) ./build/devdoc/mapping-diagram-$*.png layers/$*/mapping_diagram.png

# generate all etl and mapping graphs
generate-devdoc: $(addprefix etl-graph-,$(layers)) $(addprefix mapping-graph-,$(mappingLayers))

.PHONY: import-sql-dev
import-sql-dev:
	docker-compose run $(DC_OPTS) openmaptiles-tools bash

.PHONY: import-osm-dev
import-osm-dev:
	docker-compose run $(DC_OPTS) import-osm /bin/bash

# the `download-geofabrik` error message mention `list`, if the area parameter is wrong. so I created a similar make command
.PHONY: list
list:
	docker-compose run $(DC_OPTS) import-osm  ./download-geofabrik-list.sh

# same as a `make list`
.PHONY: download-geofabrik-list
download-geofabrik-list:
	docker-compose run $(DC_OPTS) import-osm  ./download-geofabrik-list.sh

.PHONY: download-wikidata
download-wikidata:
	mkdir -p wikidata && docker-compose run $(DC_OPTS) --entrypoint /usr/src/app/download-gz.sh import-wikidata

.PHONY: psql-list-tables
psql-list-tables:
	docker-compose run $(DC_OPTS) import-osm ./psql.sh  -P pager=off  -c "\d+"

.PHONY: psql-pg-stat-reset
psql-pg-stat-reset:
	docker-compose run $(DC_OPTS) import-osm ./psql.sh  -P pager=off  -c 'SELECT pg_stat_statements_reset();'

.PHONY: forced-clean-sql
forced-clean-sql:
	docker-compose run $(DC_OPTS) import-osm ./psql.sh -c "DROP SCHEMA IF EXISTS public CASCADE ; CREATE SCHEMA IF NOT EXISTS public; "
	docker-compose run $(DC_OPTS) import-osm ./psql.sh -c "CREATE EXTENSION hstore; CREATE EXTENSION postgis; CREATE EXTENSION unaccent; CREATE EXTENSION fuzzystrmatch; CREATE EXTENSION osml10n; CREATE EXTENSION pg_stat_statements;"
	docker-compose run $(DC_OPTS) import-osm ./psql.sh -c "GRANT ALL ON SCHEMA public TO public;COMMENT ON SCHEMA public IS 'standard public schema';"

.PHONY: pgclimb-list-views
pgclimb-list-views:
	docker-compose run $(DC_OPTS) import-osm ./pgclimb.sh -c "select schemaname,viewname from pg_views where schemaname='public' order by viewname;" csv

.PHONY: pgclimb-list-tables
pgclimb-list-tables:
	docker-compose run $(DC_OPTS) import-osm ./pgclimb.sh -c "select schemaname,tablename from pg_tables where schemaname='public' order by tablename;" csv

.PHONY: psql-vacuum-analyze
psql-vacuum-analyze:
	@echo "Start - postgresql: VACUUM ANALYZE VERBOSE;"
	docker-compose run $(DC_OPTS) import-osm ./psql.sh  -P pager=off  -c 'VACUUM ANALYZE VERBOSE;'

.PHONY: psql-analyze
psql-analyze:
	@echo "Start - postgresql: ANALYZE VERBOSE ;"
	docker-compose run $(DC_OPTS) import-osm ./psql.sh  -P pager=off  -c 'ANALYZE VERBOSE;'

.PHONY: list-docker-images
list-docker-images:
	docker images | grep openmaptiles

.PHONY: refresh-docker-images
refresh-docker-images:
	docker-compose pull --ignore-pull-failures

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
