# place

The place layer consists out of [countries](http://wiki.openstreetmap.org/wiki/Tag:place%3Dcountry),
[states](http://wiki.openstreetmap.org/wiki/Tag:place%3Dstate) and [cities](http://wiki.openstreetmap.org/wiki/Key:place).
Apart from the roads this is also one of the more important layers to create a beautiful map.
We suggest you use different font styles and sizes to create a text hierarchy.

## Fields

- **name_en**: The english `name:en` value if available.
- **name**: The OSM [`name`](http://wiki.openstreetmap.org/wiki/Key:name) value of the POI.
- **rank**: Countries, states and the most important cities all have a `rank` field ranging from `1` to `6` which
marks the importance of the feature. Less important places do not have a `rank`.
Use this to build a text hierarchy. The rank value originates from Natural Earth data and is either the
original `scalerank` for cities or the original `labelrank` for countries and states.
- **class**: Distinguish between `country`, `state` and other city classes like
`city`, `town`, `village`, `hamlet`, `suburb`, `neighbourhood` or `isolated_dwelling`.
Use this to separately style the different places according to their importance (usually country and state different
than cities).

## Mapping

![](mapping.png)


