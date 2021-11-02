# Introduction

Thank you for considering contributing to OpenMapTiles. It's people like you that make OpenMapTiles such a great project. Talk to us at the OSM Slack **#openmaptiles** channel ([join](https://osmus-slack.herokuapp.com/)).

Following these guidelines helps to communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

OpenMapTiles is an open source project and we love to receive contributions from our community — you! There are many ways to contribute, from writing tutorials or blog posts, improving the documentation, submitting bug reports and feature requests or writing code which can be incorporated into OpenMapTiles itself.

# Ground Rules

 * Create issues for any major changes and enhancements that you wish to make. Discuss things transparently and get community feedback.
 * Keep feature versions as small as possible, preferably one new feature per version.
 * Be welcoming to newcomers and encourage diverse new contributors from all backgrounds. See the [Python Community Code of Conduct](https://www.python.org/psf/codeofconduct/).

# Getting started

1. Create your own fork of the code
1. Do the changes in your fork
1. Create a pull request

# Code review process

We all make mistakes and bad coding decisions. So apart from the obvious fixes, all changes must be reviewed by another 2 members of the project. This also helps with the [bus factor](https://en.wikipedia.org/wiki/Bus_factor) -- there should always be other people in the team who know why a change was made.

For any non-trivial changes, all pull requests must be approved by at least three members of the OpenMapTiles team. Afterwards you can merge the PR if you have rights, or another person must do it for you.

Your pull request must:

 * Address a single issue or add a single item of functionality.
 * Contain a clean history of small, incremental, logically separate commits,
   with no merge commits.
 * Use clear commit messages.
 * Be possible to merge automatically.

When you modify import data rules in `mapping.yaml` or `*.sql`, please update:

1. field description in `[layer].yaml`
2. comments starting with `#etldoc`
3. regenerate documentation graphs with `make generate-devdoc`
4. update layer description on https://openmaptiles.org/schema/ (https://github.com/openmaptiles/www.openmaptiles.org/tree/master/layers)
5. check if OMT styles are affected by the PR and if there is a need for style updates

When you are making PR that adds new spatial features to OpenMapTiles schema, please make also PR for at least one of our GL styles to show it on the map. Visual check is crucial.

# SQL unit testing

It is recommended that you create a [unit test](TESTING.md) when modifying the behavior of the SQL layer.  This will ensure that your changes are working as expected when importing or updating OSM data into an OpenMapTiles database.

# Verifying that updates still work

When testing a PR, you shoud also verify that the update process completes without error.  The following procedure will run the update process.

1. Change .env to set `DIFF_MODE=true`.  In addition, if you're testing changes that impact zooms higher than the default zoom of 7, you should also change `MAX_ZOOM` to be up to 14.
2. Set the test area to the appropriate geofabrik extract, for example:

```
export area=north-america/us/indiana
```

3. Build 1-month-old tiles:

```
rm -fr data build cache
make download-geofabrik area=$area
docker-compose run --rm --user=$(id -u):$(id -g) openmaptiles-tools sh -c "wget -O data/$area.osm.pbf http://download.geofabrik.de/$area-$(date --date="$(date +%Y-%m-15) -1 month" +'%y%m01').osm.pbf"
./quickstart.sh $area
```
4. Update with the changes since then:
```
docker-compose run --rm --user=$(id -u):$(id -g) openmaptiles-tools sh -c "osmupdate --base-url=$(sed -n 's/ *\"replication_url\": //p' data/$area.repl.json) data/$area.osm.pbf data/changes.osc.gz"
make import-diff
make generate-tiles-pg
```
