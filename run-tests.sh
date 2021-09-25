#!/bin/sh

# Clean initial state with data import
make refresh-docker-images
make destroy-db
make init-dirs
make clean
make all
make start-db
make import-data
make import-borders

# Load unit tests and sample data into SQL
make test-schema-import

# Import data with unit tests to follow
make import-sql

# TODO: update
