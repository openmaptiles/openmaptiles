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

You can use imposm3 to keep the database updated (thanks to the [work by @stirringhalo](https://github.com/openmaptiles/openmaptiles/pull/131)).
This will repeatedly download the OSM change feed and import it into the database.
In order to be able to update the database, the initial download and import of the OSM data must be done when `DIFF_MODE=true` is set in the `.env` file.
In this mode the initial download also sets the update source and the update intervals.

To start the update process please use
```
make start-update-osm
```

To stop the update process please use
```
make stop-update-osm
```

After each update activation, **imposm3** will store lists of updated tiles in text format in subfolders of the `diffdir`,
named for the date(s) on which the import took place (`YYYYMMDD`).

See [Generate Changed Tiles](#generate-changed-tiles) below on how this file can be used.

#### Note
When the update process is actively updating the DB it is impossible to successfully generate tiles,
as there will be conflicts and deadlocks related to the DB access.

Unfortunately, there is no known way to execute an external command in-between rounds of the `update-osm` process.

#### Troubleshooting

The log file for osm update can be viewed using

```
docker-compose logs --tail 100 --follow update-osm
```

Use `Ctrl-C` to stop following the log.

The output will be similar to this:

```
[info] Importing #4889572 including changes till ....... +0000 UTC (2h10m10s behind)
```

It might take some time to catch up with the latest changes, but the "time behind" should decrease until it is a few minutes.
If it doesn't, you need to download a new extract or check that there are enough system resources to keep-up with the changes.

Finally you will get an output like this - this indicates, that some 6 objects were changed:

```
[progress]     3s C:       0/s (0) N:       0/s (0) W:       0/s (6) R:      0/s (0)
```

The process will keep running foreverprint something like this - which just means that no changes were in the latest changeset:

```
[progress]     0s C:       0/s (0) N:       0/s (0) W:       0/s (0) R:      0/s (0)
```

### Import Change File

You may perform a one-time import of OSM changes from the `changes.osc.gz` file in your import folder using

```
make import-diff
```

Similar to[Keep Database Updated](#keep_database_updated) above, **imposm3** will store the list of updated tiles in text file in subfolders of the `diffdir`,
named for the date on which the import took place (`YYYYMMDD`).

See [Generate Changed Tiles](#generate-changed-tiles) below.

#### Note
There is no `make` command for downloading OSM changes into `changes.osc.gz`.
You may perform this task using [`osmupdate`](https://wiki.openstreetmap.org/wiki/Osmupdate),
[pyosmium-get-changes](https://docs.osmcode.org/pyosmium/latest/tools_get_changes.html),
or downloading the changefile directly from the replication server.

## Generate Changed Tiles

To generate all changed tiles, based on the lists of all updated tiles, and update the existing MBtiles file, please use

```
make generate-changed-tiles
```
