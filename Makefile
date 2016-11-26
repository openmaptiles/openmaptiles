all: build/openmaptiles.tm2source/data.yml build/mapping.yaml build/tileset.sql

.PHONY: docs
docs: layers/railway/README.md layers/boundary/README.md layers/water/README.md layers/building/README.md layers/transportation/README.md layers/transportation_name/README.md layers/poi/README.md layers/place/README.md layers/waterway/README.md layers/water_name/README.md layers/landcover/README.md layers/landuse/README.md layers/housenumber/README.md

build/openmaptiles.tm2source/data.yml:
	mkdir -p build/openmaptiles.tm2source && generate-tm2source openmaptiles.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > build/openmaptiles.tm2source/data.yml

build/mapping.yaml:
	mkdir -p build && generate-imposm3 openmaptiles.yaml > build/mapping.yaml

build/tileset.sql:
	mkdir -p build && generate-sql openmaptiles.yaml > build/tileset.sql

layers/poi/README.md:
	generate-doc layers/poi/poi.yaml --diagram layers/poi/mapping > layers/poi/README.md

layers/transportation/README.md:
	generate-doc layers/transportation/transportation.yaml --diagram layers/transportation/mapping > layers/transportation/README.md

layers/transportation_name/README.md:
	generate-doc layers/transportation_name/transportation_name.yaml > layers/transportation_name/README.md

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
	rm -f build/openmaptiles.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql
