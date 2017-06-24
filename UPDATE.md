# Keep the vector tiles updated

Once you have imported OpenMapTiles you can also keep it up to date by importing the latest OSM changes and
regenerating the tables.

## Import

You can either keep the database up to date based on the daily OSM change feed
or import specific change files.

### Keep Database Updated

You can use the new imposm3 feature to keep the database updated (thanks to the [work by @stirringhalo](https://github.com/openmaptiles/openmaptiles/pull/131)). This will automatically download
the OSM change feed and import it into the database.
After each run you should also have a list of tiles that have updated.

```
docker-compose run update-osm
```

### Import Change File

Given you have a file `changes.osc.gz` in your import folder. Once you ran the import command you should also have a list of tiles that have updated.

```
docker-compose run import-osm-diff
```

## Generate Changed Tiles

After the import has finished **imposm3** will store a list of tiles in text format in the `diffdir`.
Copy the as `tiles.txt` to the import folder.

Now run the command to read the tilelist and write the vector tiles for it to a new MBTiles.

```
docker-compose run generate-changed-vectortiles
```
