all: build/openmaptiles.tm2source/data.yml build/mapping.yaml build/tileset.sql layers/railway/README.md

build/openmaptiles.tm2source/data.yml:
	mkdir -p build/openmaptiles.tm2source && generate-tm2source openmaptiles.yaml --host="postgres" --port=5432 --database="openmaptiles" --user="openmaptiles" --password="openmaptiles" > build/openmaptiles.tm2source/data.yml

build/mapping.yaml:
	mkdir -p build && generate-imposm3 openmaptiles.yaml > build/mapping.yaml

build/tileset.sql:
	mkdir -p build && generate-sql openmaptiles.yaml > build/tileset.sql

layers/railway/README.md:
	generate-doc layers/railway/railway.yaml --diagram layers/railway/mapping > layers/railway/README.md

clean:
	rm -f build/openmaptiles.tm2source/data.yml && rm -f build/mapping.yaml && rm -f build/tileset.sql && rm -f layers/**/README.md&& rm -f layers/**/*.png
