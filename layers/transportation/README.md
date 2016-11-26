# highway

Roads or [`highway`](http://wiki.openstreetmap.org/wiki/Key:highway) in OpenStreetMap lingo.
This layer is directly derived from the OSM road hierarchy which is why it is called `highway`. Only
at zoom level 4 to 7 some major highways from Natural Earth are used otherwise it is only OSM data.
It contains all roads from motorways to primary, secondary and tertiary roads to residential roads and
foot paths. Styling the roads is the most essential part of the map. If you can put enough effort into it
makes sense to carefully style each `subclass`. For more comfortable styling you can also just style the roads
by `class`. Roads can have different properties, a road can have `oneway=yes` and `bridge=yes` at the same time.
These properties are reflected in the field `properties`.
This layer is not meant for labelling the roads (the purpose of the layer `highway_name`).

The `highway` layer also contains polygons for things like plazas.

## Fields

- **class**: Either `motorway`, `major_road` (containing `trunk`, `primary`, `secondary` and `tertiary` roads) and `minor_road` (less important roads in the hierarchy like `residential` or `service`) or `path` for
non vehicle paths (such as `cycleway` or `footpath`).
- **subclass**: Original value of the [`highway`](http://wiki.openstreetmap.org/wiki/Key:highway) tag. Use this to do more
precise styling.
- **properties**: Additional properties describing the nature of road.
The properties `bridge` and `tunnel` can be combined with `oneway` as well. So to style all bridges the same you
should style both the properties `bridge` and `bridge:oneway`.
Properties can be one of `bridge:oneway`, `tunnel:oneway`, `ramp`, `ford`, `bridge`, `tunnel` or`oneway`.

## Mapping

![](mapping.png)


