#!/bin/sh

# Exit on error
set -e

# Clean initial state with data import
export area=changes
make refresh-docker-images
make destroy-db
make init-dirs
make clean
make all
make start-db
make import-data

# Load test case data into SQL
make import-test-data

make import-sql

# Run unit tests
make test-schema-import

# Import canned diff file
make import-update-data
make import-diff area=changes

# Load unit tests and sample data into SQL
make test-schema-update

