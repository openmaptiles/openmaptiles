all: build/openmaptiles.tm2source/data.yml build/mapping.yaml build/tileset.sql

.PHONY: docs
docs: layers/railway/README.md layers/boundary/README.md layers/water/README.md layers/building/README.md layers/highway/README.md layers/highway_name/README.md layers/poi/README.md


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

layers/water/README.md:
	generate-doc layers/water/water.yaml --diagram layers/water/mapping > layers/water/README.md

layers/building/README.md:
	generate-doc layers/building/building.yaml > layers/building/README.md

clean:
	rm -f build/openmaptiles.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql && rm -f layers/**/README.md&& rm -f layers/**/*.png
