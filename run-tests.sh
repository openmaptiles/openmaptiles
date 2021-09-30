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

make import-sql

# Load unit tests and sample data into SQL and run tests
make test-schema-import

# Load unit tests and sample data into SQL
make test-schema-update

# Import canned diff file
make import-diff area=changes
