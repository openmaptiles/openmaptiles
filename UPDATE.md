# Keeping the Vector Tiles Updated

Once you have imported OpenMapTiles you can also keep it up to date by importing the latest OSM changes and
regenerating the tables.

## Import

You can either keep the database up to date based on the daily (or minutely) OSM change feed
or import specific change files.

### Choosing the Download Source

While GeoFabrik currently provides extracts of basically all countries, they provide only daily updates. 
If you need minutely updates you might want to try openstreetmap.fr, for example like this: `make download-osmfr area=africa/eritrea`, which configures minutely updates.

### Preparations

If you plan to keep data updated automatically, before importing any data, make sure to set 

```
DIFF_MODE=true
```
    
in the `.env`

Now download fresh data:

``` 
make download area=your-area-of-choice
```

### Keep Database Updated

You can use the new imposm3 feature to keep the database updated (thanks to the [work by @stirringhalo](https://github.com/openmaptiles/openmaptiles/pull/131)). This will automatically download
the OSM change feed and import it into the database.
After each run you should also have a list of tiles that have updated.

```
make update-osm
```

#### Troubleshooting

The output will be similar to this:

``` 
[info] Importing #4889572 including changes till ....... +0000 UTC (1m13s behind)
``` 

It might take some time to catch up with the latest changes, but the "time behind" should always decrease. If it doesn't, you need to download a new extract our don't have enough system resources to keep-up with the changes.

### Import Change File

Given you have a file `changes.osc.gz` in your import folder. Once you ran the import command you should also have a list of tiles that have updated.

```
make import-diff
```

## Generate Changed Tiles

After the import has finished **imposm3** will store lists of tiles in text format in subfolders of the `diffdir`,
named for the date(s) on which the import took place (`YYYYMMDD`).
Copy and merge the files to `tiles.txt` in the import folder (`data`), either manually or with the following command, which also removes duplicate tiles so they are only generated once:  
```
cd data && sort ./*/*.tiles | uniq > tiles.txt
```

Now run the command to read the tilelist and write the vector tiles for it to a new MBTiles.

```
docker-compose run generate-changed-vectortiles
```
