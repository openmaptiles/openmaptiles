all: build/openmaptiles.tm2source/data.yml build/mapping.yaml build/tileset.sql

.PHONY: docs
docs: layers/railway/README.md layers/boundary/README.md layers/water/README.md layers/building/README.md layers/highway/README.md layers/highway_name/README.md layers/poi/README.md layers/place/README.md layers/waterway/README.md layers/water_name/README.md layers/landcover/README.md layers/landuse/README.md layers/housenumber/README.md

build/openmaptiles.tm2source/data.yml:
	mkdir -p build/openmaptiles.tm2source && generate-tm2source openmaptiles.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > build/openmaptiles.tm2source/data.yml

build/mapping.yaml:
	mkdir -p build && generate-imposm3 openmaptiles.yaml > build/mapping.yaml

build/tileset.sql:
	mkdir -p build && generate-sql openmaptiles.yaml > build/tileset.sql

layers/poi/README.md:
	generate-doc layers/poi/poi.yaml --diagram layers/poi/mapping > layers/poi/README.md

layers/highway/README.md:
	generate-doc layers/highway/highway.yaml --diagram layers/highway/mapping > layers/highway/README.md

layers/highway_name/README.md:
	generate-doc layers/highway_name/highway_name.yaml > layers/highway_name/README.md

layers/railway/README.md:
	generate-doc layers/railway/railway.yaml --diagram layers/railway/mapping > layers/railway/README.md

layers/boundary/README.md:
	generate-doc layers/boundary/boundary.yaml --diagram layers/boundary/mapping > layers/boundary/README.md

layers/water_name/README.md:
	generate-doc layers/water_name/water_name.yaml > layers/water_name/README.md

layers/water/README.md:
	generate-doc layers/water/water.yaml --diagram layers/water/mapping > layers/water/README.md

layers/waterway/README.md:
	generate-doc layers/waterway/waterway.yaml --diagram layers/waterway/mapping > layers/waterway/README.md

layers/building/README.md:
	generate-doc layers/building/building.yaml > layers/building/README.md

layers/place/README.md:
	generate-doc layers/place/place.yaml --diagram layers/place/mapping > layers/place/README.md

layers/landuse/README.md:
	generate-doc layers/landuse/landuse.yaml --diagram layers/landuse/mapping > layers/landuse/README.md

layers/landcover/README.md:
	generate-doc layers/landcover/landcover.yaml --diagram layers/landcover/mapping > layers/landcover/README.md

layers/housenumber/README.md:
	generate-doc layers/housenumber/housenumber.yaml > layers/housenumber/README.md

clean:
	rm -f build/openmaptiles.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql && rm -f layers/**/README.md&& rm -f layers/**/*.png

clean_build:
	rm -f build/openmaptiles.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql

clean-docker:
	docker-compose down -v --remove-orphans
	docker-compose rm -fv
	docker volume ls -q | grep openmaptiles  | xargs -r docker volume rm || true

list-docker-images:
	docker images | grep openmaptiles

refresh-docker-images:
	docker pull openmaptiles/generate-vectortiles
	docker pull openmaptiles/import-lakelines
	docker pull openmaptiles/import-natural-earth
	docker pull openmaptiles/import-osm
	docker pull openmaptiles/import-sql
	docker pull openmaptiles/import-water
	docker pull openmaptiles/openmaptiles-tools
	docker pull openmaptiles/postgis
	docker pull osm2vectortiles/mapbox-studio

remove-docker-images:
	docker rmi openmaptiles/generate-vectortiles
	docker rmi openmaptiles/import-lakelines
	docker rmi openmaptiles/import-natural-earth
	docker rmi openmaptiles/import-osm
	docker rmi openmaptiles/import-sql
	docker rmi openmaptiles/import-water
	docker rmi openmaptiles/openmaptiles-tools
	docker rmi openmaptiles/postgis
	docker rmi osm2vectortiles/mapbox-studio

psql:
	docker-compose run --rm import-osm /usr/src/app/psql.sh

psql-list-tables:
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c "\d+"

psql-pg-stat-reset:
	docker-compose run --rm import-osm /usr/src/app/psql.sh  -P pager=off  -c 'SELECT pg_stat_statements_reset();'

forced-clean-sql:
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "DROP SCHEMA IF EXISTS public CASCADE"
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "CREATE SCHEMA IF NOT EXISTS public"
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "CREATE EXTENSION hstore"
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "CREATE EXTENSION postgis"
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "CREATE EXTENSION pg_stat_statements"
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "GRANT ALL ON SCHEMA public TO postgres;"
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "GRANT ALL ON SCHEMA public TO public;"
	docker-compose run --rm import-osm /usr/src/app/psql.sh -c "COMMENT ON SCHEMA public IS 'standard public schema';"

pgclimb-list-views:
	docker-compose run --rm import-osm /usr/src/app/pgclimb.sh -c "select schemaname,viewname from pg_views where schemaname='public' order by viewname;" csv

pgclimb-list-tables:
	docker-compose run --rm import-osm /usr/src/app/pgclimb.sh -c "select schemaname,tablename from pg_tables where schemaname='public' order by tablename;" csv

import-sql-dev:
	docker-compose run --rm import-sql /bin/bash

import-osm-dev:
	docker-compose run --rm import-osm /bin/bash

download-geofabrik:
	@echo ===============  download-geofabrik =======================
	@echo Download area :   $(area)
	@echo [[ example: make download-greofabrik  area=albania ]]
	@echo [[ list areas:  make download-geofabrik-list       ]]
	docker-compose run --rm import-osm  ./download-geofabrik.sh $(area)
	ls -la ./data/$(area).*
	@echo "Generated config file: ./data/docker-compose-config.yml"
	@echo " " 	
	cat ./data/docker-compose-config.yml 
	@echo " " 	

list:
	docker-compose run --rm import-osm  ./download-geofabrik-list.sh

download-geofabrik-list:
	docker-compose run --rm import-osm  ./download-geofabrik-list.sh

start-mapbox-studio:
	docker-compose up mapbox-studio

etlgraph:
	generate-etlgraph layers/boundary/boundary.yaml
	generate-etlgraph layers/highway/highway.yaml
	generate-etlgraph layers/housenumber/housenumber.yaml
	generate-etlgraph layers/landuse/landuse.yaml
	generate-etlgraph layers/poi/poi.yaml
	generate-etlgraph layers/water/water.yaml
	generate-etlgraph layers/waterway/waterway.yaml
	generate-etlgraph layers/building/building.yaml
	generate-etlgraph layers/highway_name/highway_name.yaml
	generate-etlgraph layers/landcover/landcover.yaml
	generate-etlgraph layers/place/place.yaml
	generate-etlgraph layers/railway/railway.yaml
	generate-etlgraph layers/water_name/water_name.yaml

