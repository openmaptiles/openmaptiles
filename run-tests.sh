#!/bin/sh

# Clean initial state with data import
make refresh-docker-images
make destroy-db
make init-dirs
make clean
make all
make start-db
make import-data

#Temp hack
make download-geofabrik area=andorra
make import-borders area=andorra

# Load unit tests and sample data into SQL
make test-schema-import

# Import data with unit tests to follow
make import-sql

# Load unit tests and sample data into SQL
#echo DIFF_MODE=true >> .env
#make test-schema-update

# Import canned diff file
#make import-diff area=changes
