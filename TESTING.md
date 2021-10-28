
# OpenMapTiles SQL Testing

The OpenMapTiles SQL tests ensure that OSM data is properly imported and updated in the OpenMapTiles data schema.  The tests work by injecting test OSM data into the database and checking to ensure that the data is properly reflected in the SQL output. 

Usage:

`make clean && make sql-test`

## How it works

The SQL tests consist of the following parts:

 1. **Test import data**, located in `tests/import`.  This test data is in the [OSM XML](https://wiki.openstreetmap.org/wiki/OSM_XML) format and contains the data that should be initially injected into the database.  The files are numbered in order to ensure that each test data file OSM id numbers that are unique from the other files.  For example, the file starting with `100` will use node ids from 100000-199999, way ids from 1000-1999, and relation ids from 100-199.
 2. **Test update data**, located in `tests/update`.  This test data is in the [osmChange XML](https://wiki.openstreetmap.org/wiki/OsmChange) format, and contains the data that will be used to update the test import data (in order to verify that the update process is working correctly.  These files are also numbered using the same scheme as the test import data.
 3. **Import SQL test script**, located at `tests/test-post-import.sql`.  This script is executed after the test import data has been injected, and runs SQL-based checks to ensure that the import data was properly imported.  If there are failures in the tests, an entry will be added to the table `omt_test_failures`, with one record per error that occurs during the import process.  A test failure will also fail the build.  To inspect the test failure messages, run `make psql` and issue the comment `SELECT * FROM omt_test_failures`.
 4. **Update SQL test script**, located at `tests/test-post-update.sql`.  This script performs the same function as the import test script, except that it occurs after the test update data has been applied to the database.  Note that script will only run if the import script passes all tests.

