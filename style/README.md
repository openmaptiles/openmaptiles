## OSM OpenMapTiles style

OSM OpenMapTiles style is inspired by [OSM Carto](https://github.com/gravitystorm/openstreetmap-carto). 
Its purpose is to display all features in vector tiles.

### Fonts

OSM OpenMapTiles style used _Noto Sans_ fonts. 
To download these fonts run:
```bash
make download-fonts
```
It downloads _Noto Sans_ fonts (~70MB) and extract them into [openmaptiles/data/fonts](../data/fonts) directory.

### Icons/sprite

All icons which are used OpenMapTiles style are located in [openmaptiles/style/icons](icons). 
After the style is built, the icons are composed into sprite files located in `build` directory. 

Additional svg icons can be added to [openmaptiles/style/icons](icons) directory. 

To generate new sprite files with added icons, run: 
```bash
make build-sprite
``` 
Sprite files will be generated into `build` directory.

### Build style

To build style run:
```bash
make build-style
```
It generates new sprite files and merges all style snippets from each layer, orders them according the `order` value 
and saves the complete style into `build/style/style.json`.

### Tileserver-gl
The tileserver serves both the tiles and the OSM OpenMapTiles map. 
#### MBTiles (default)
By default, the tileserver serves OSM OpenMapTiles map based on tiles from `data/tiles.mbtiles` as defined in 
[style-header.json](./style-header.json).
```json
"sources": {
  "openmaptiles": {
    "type": "vector",
    "url": "mbtiles:///data/tiles.mbtiles"
  },
  ...
}
```
#### Serve from the db
The tileserver can also serve OSM OpenMapTiles map based on dynamically generated tiles directly from the database. 
Start the database container and the postserve container: 
```bash
make start-db
make start-postserve
```
In [style-header.json](./style-header.json) change the source of tiles to PostServe:

#### Start tileserver
Before you start the tileserver, make sure you have fonts downloaded in [openmaptiles/data/fonts](../data/fonts), 
sprites generated and style built:
```bash
make download-fonts
make build-style
```
Start tileserver:
```bash
make start-tileserver
```
And go to http://localhost:8080.
