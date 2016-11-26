# highway_name

This is the layer for labelling the highways. Only highways that are named `name=*` and are long enough
to place text upon appear. The OSM roads are stitched together if they contain the same name
to have better label placement than having many small linestrings.
For motorways you should use the `ref` field to label them while for other roads you should use `name`.

## Fields

- **ref**: The OSM [`ref`](http://wiki.openstreetmap.org/wiki/Key:ref) tag of the motorway or road.
- **ref_length**: Length of the `ref` field. Useful for having a shield icon as background for labeling motorways.
- **name**: The OSM [`name`](http://wiki.openstreetmap.org/wiki/Highways#Names_and_references) value of the highway.
- **subclass**: Original value of the [`highway`](http://wiki.openstreetmap.org/wiki/Key:highway) tag. Use this to do more
precise styling.
- **class**: Either `motorway`, `major_road` (containing `trunk`, `primary`, `secondary` and `tertiary` roads) and `minor_road` (less important roads in the hierarchy like `residential` or `service`) or `path` for
non vehicle paths (such as `cycleway` or `footpath`).



