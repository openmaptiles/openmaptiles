#! /bin/bash
# to run this script you need kosmitc and the openmaptiles-tools loaded

set -e

KOSMETIK=kosmtik

for tiles in 'base' 'poi' 'lite'; do
    tileset="openmaptiles_$tiles.yaml"
    generate-sql $tileset > generated_$tiles.sql
    generate-imposm3 $tileset > generated_mapping_$tiles.yaml
    TMP_SOURCE=generated_${tiles}_tm2source.yml
    generate-tm2source $tileset  --host="localhost" --port=5432 --database="osm" --user="osm" --password="osm" > $TMP_SOURCE
    $KOSMETIK export $TMP_SOURCE > generated_source_$tiles.xml
    rm $TMP_SOURCE
done
