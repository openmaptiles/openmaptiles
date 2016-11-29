all: build/openmaptiles.tm2source/data.yml build/mapping.yaml build/tileset.sql

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
	@echo [[ example: make download-geofabrik  area=albania ]]
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

test_etlgraph:
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
