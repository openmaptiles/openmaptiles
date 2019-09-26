## To determine whether any changes are a notable loss in performance:

1. Start with the old approach
2. Use a fresh database
3. Use a large extract, such as France, Germany, Britain, etc. Too small of PBFs may be entirely cached in RAM and not representative of planet performance
4. Time the extract, ensuring you have the desired zoom level as set in .env
5. Switch to the new approach and use a fresh database once again
6. Quickstart.log will have all the time logs.
7. If necessary, run an update as well to see if your approach can keep up with live updates on the chosen interval. Currently, weekly updates are the target.

## To determine whether your changes in SQL are lossless:

It is recommended to use the "sqldiff" tool to compare mbtiles.

`sqldiff --table tiles new.mbtiles old.mbtiles`

This will compare on just the tiles table, ensuring for each zoom, x, y that the tile data is the same between both mbtiles. If sqldiff returns nothing, it means the results are identical.
