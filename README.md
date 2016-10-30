## OpenMapTiles

OpenMapTiles is a collection of vector tile layers you can mix and match to create your own vector tile sets.

## Layers

### Standard Layers

OpenMapTiles contains a collection of Natural Earth and OSM based layers (with imposm3 mapping) you can modify and adapt.
We welcome new standard layers from other data sources or import tools (like osm2pgsql with ClearTables).

Each layer is documented and self contained. Click on the link for each layer to get more information.
Layers can be chosen to create a *Tileset* like the `openmaptiles.yaml` tileset.

- [boundary](layers/boundary/README.md)
- [building](layers/building/README.md)
- [highway](layers/highway/README.md)
- [highway_name](layers/highway_name/README.md)
- [housenumber](layers/housenumber/README.md)
- [landcover](layers/landcover/README.md)
- [landuse](layers/landuse/README.md)
- [place](layers/place/README.md)
- [poi](layers/poi/README.md)
- [railway](layers/railway/README.md)
- [water](layers/water/README.md)
- [water_name](layers/water_name/README.md)
- [waterway](layers/waterway/README.md)

### Define your own Layer

### Define your own Tileset

## Work on the Standard Layers

To work on *osm2vectortiles.tm2source* you need Docker and Python.

- Install [Docker](https://docs.docker.com/engine/installation/)
- Install [Docker Compose](https://docs.docker.com/compose/install/)
- Install [OpenMapTiles tools](https://github.com/openmaptiles/openmaptiles-tools) with `pip install openmaptiles-tools`

### Build

Build the tileset.

```
# Build the imposm mapping, the tm2source project and collect all SQL scripts
make
# You can also run the build process inside a Docker container
docker run -v $(pwd):/tileset openmaptiles/openmaptiles-tools make
```

### Prepare the Database

Now start up the database container.

```bash
docker-compose up -d postgres`
```

Import water from [OpenStreetMapData](http://openstreetmapdata.com/).

```bash
docker-compose run import-water
```

Import [Natural Earth](http://www.naturalearthdata.com/) data.

```bash
docker-compose run import-natural-earth
```

Import [Lake center line](https://github.com/lukasmartinelli/osm-lakelines) data.

```bash
docker-compose run import-lakelines
```

Import [OpenStreetMap](http://wiki.openstreetmap.org/wiki/Osm2pgsql) data based on the [ClearTables osm2pgsql style](https://github.com/ClearTables/ClearTables).
In order to do this you first need to clone the latest ClearTables.

```bash
docker-compose run import-osm
```

### Work on Layers

Each time you modify layer SQL code run `make` and `docker-compose run import-sql`.

```
make clean && make && docker-compose run import-sql
```

To look at the vector tiles you can start up Mapbox Studio Classic in a container
and visit `localhost:3000` and open the vector source project under `/projects`.

```bash
docker-compose up mapbox-studio
```

![Develop on OSM2VectorTiles with Mapbox Studio Classic](./mapbox_studio_classic.gif)

## License

All code in this repository is under the [MIT license](./LICENSE) and the cartography decisions encoded in the schema and SQL is licensed under [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
