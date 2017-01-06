## OpenMapTiles

OpenMapTiles is an extensible and open vector tile schema for a OpenStreetMap basemap. It is used to generate vector tiles for [openmaptiles.org](http://openmaptiles.org/) and [openmaptiles.com](http://openmaptiles.com/).

We encourage you to collaborate, reuse and adapt existing layers and add your own layers or use our approach for your own vector tile project. The repository is built on top of the [openmaptiles/tools](https://github.com/openmaptiles/openmaptiles-tools) to simplify vector tile creation.

- :link: Docs http://openmaptiles.org/docs
- :link: Schema: http://openmaptiles.org/schema
- :link: Production package: http://openmaptiles.com/

## Styles

You can start from several GL styles supporting the OpenMapTiles vector schema.

:link: [Learn how to create Mapbox GL styles with Maputnik and OpenMapTiles](http://openmaptiles.org/docs/style/maputnik/).


- [OSM Bright](https://github.com/openmaptiles/osm-bright-gl-style)
- [Positron](https://github.com/openmaptiles/positron-gl-style)
- [Dark Matter](https://github.com/openmaptiles/dark-matter-gl-style)
- [Klokantech Basic](https://github.com/openmaptiles/klokantech-basic-gl-style)
- [Klokantech 3D](https://github.com/openmaptiles/klokantech-3d-gl-style)
- [Fiord Color](https://github.com/openmaptiles/fiord-color-gl-style)
- [Toner](https://github.com/openmaptiles/toner-gl-style)

We also ported over our favorite old raster styles (TM2).

:link: [Learn how to create TM2 styles with Mapbox Studio Classic and OpenMapTiles](http://openmaptiles.org/docs/style/mapbox-studio-classic/).

- [Light](https://github.com/openmaptiles/mapbox-studio-light.tm2/)
- [Dark](https://github.com/openmaptiles/mapbox-studio-dark.tm2/)
- [OSM Bright](https://github.com/openmaptiles/mapbox-studio-osm-bright.tm2/)
- [Pencil](https://github.com/openmaptiles/mapbox-studio-pencil.tm2/)
- [Woodcut](https://github.com/openmaptiles/mapbox-studio-woodcut.tm2/)
- [Pirates](https://github.com/openmaptiles/mapbox-studio-pirates.tm2/)
- [Wheatpaste](https://github.com/openmaptiles/mapbox-studio-wheatpaste.tm2/)

## Schema

OpenMapTiles consists out of a collection of documented and self contained layers you can modify and adapt.
Together the layers make up the OpenMapTiles tileset.

:link: [Study the vector tile schema](http://openmaptiles.org/schema)

- [boundary](https://github.com/openmaptiles/openmaptiles/wiki/boundary)
- [building](https://github.com/openmaptiles/openmaptiles/wiki/building)
- [transportation](https://github.com/openmaptiles/openmaptiles/wiki/transportation)
- [transportation_name](https://github.com/openmaptiles/openmaptiles/wiki/transportation_name)
- [housenumber](https://github.com/openmaptiles/openmaptiles/wiki/housenumber)
- [landcover](https://github.com/openmaptiles/openmaptiles/wiki/landcover)
- [landuse](https://github.com/openmaptiles/openmaptiles/wiki/landuse)
- [aeroway](https://github.com/openmaptiles/openmaptiles/wiki/aeroway)
- [place](https://github.com/openmaptiles/openmaptiles/wiki/place)
- [poi](https://github.com/openmaptiles/openmaptiles/wiki/poi)
- [park](https://github.com/openmaptiles/openmaptiles/wiki/park)
- [water](https://github.com/openmaptiles/openmaptiles/wiki/water)
- [water_name](https://github.com/openmaptiles/openmaptiles/wiki/water_name)
- [waterway](https://github.com/openmaptiles/openmaptiles/wiki/waterway)

## Develop

To work on OpenMapTiles you need Docker and Python.

- Install [Docker](https://docs.docker.com/engine/installation/). Minimum version is 1.10.0+.
- Install [Docker Compose](https://docs.docker.com/compose/install/). Minimum version is 1.6.0+.
- Install [OpenMapTiles tools](https://github.com/openmaptiles/openmaptiles-tools) with `pip install openmaptiles-tools`

### Build

Build the tileset.

```bash
git clone git@github.com:openmaptiles/openmaptiles.git
cd openmaptiles
# Build the imposm mapping, the tm2source project and collect all SQL scripts
make
# You can also run the build process inside a Docker container
docker run -v $(pwd):/tileset openmaptiles/openmaptiles-tools make
```

You can execute the following manual steps (for better understanding)
or use the provided `quickstart.sh` script.

```
./quickstart.sh
```

### Prepare the Database

Now start up the database container.

```bash
docker-compose up -d postgres
```

Import external data from [OpenStreetMapData](http://openstreetmapdata.com/), [Natural Earth](http://www.naturalearthdata.com/) and  [OpenStreetMap Lake Labels](https://github.com/lukasmartinelli/osm-lakelines).

```bash
docker-compose run import-water
docker-compose run import-natural-earth
docker-compose run import-lakelines
```

Import [OpenStreetMap](http://wiki.openstreetmap.org/wiki/Osm2pgsql) data with the mapping rules from
`build/mapping.yaml` (which has been created by `make`).

```bash
docker-compose run import-osm
```

### Work on Layers

Each time you modify layer SQL code run `make` and `docker-compose run import-sql`.

```
make clean && make && docker-compose run import-sql
```

Now you are ready to **generate the vector tiles** using a single process (for a full blown distributed workflow of rendering tiles check out [openmaptiles/distributed](https://github.com/openmaptiles/distributed)). Using environment variables
you can limit the bounding box and zoom levels of what you want to generate (`docker-compose.yml`).

```
docker-compose run generate-vectortiles
```

## License

*LICENSE HAS NOT BEEN YET DECIDED*

All code in this repository is under the [MIT license](./LICENSE) and the cartography decisions encoded in the schema and SQL is licensed under [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
