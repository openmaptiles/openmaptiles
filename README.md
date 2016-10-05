## Vector Data Source

This is the data source for the vector tile schema of OSM2VectorTiles.
It contains the *tm2source* project and the required database schema (views, functions).

The vector data sources stands as separate repository to foster collaboration with Wikipedia
and make it easier to fork the style without forking OSM2VectorTiles as well.

## Requirements

This vector tile schema depends on a database containing several different data sources
which need to be imported first. You can use your own ETL process or use the Docker containers from
OSM2VectorTiles.

Your PostGIS database needs the following data imported

- [OpenStreetMap](http://wiki.openstreetmap.org/wiki/Osm2pgsql) data based on the [ClearTables osm2pgsql style](https://github.com/ClearTables/ClearTables)
- [OpenStreetMapData](http://openstreetmapdata.com/) split and simplified water polygons
- [Natural Earth](http://www.naturalearthdata.com/)

## Schema

The vector data source is using zoom level views for each layer and contains useful functions.
The PostgreSQL code can be found in `sql`.

*TODO: Write import container*
