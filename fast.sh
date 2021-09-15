#!/bin/bash

chosen_area=estonia
make clean
make all
make destroy-db
make start-db
make import-data area=$chosen_area
make download area=$chosen_area
make import-osm area=$chosen_area
make import-borders area=$chosen_area
make import-wikidata area=$chosen_area
make import-sql
make analyze-db
make test-perf-null
make generate-tiles-pg area=$chosen_area

docker ps -a
