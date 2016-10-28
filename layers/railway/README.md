# railway

The `railway` layer contains linestrings marking tracks from [OSM Railways](http://wiki.openstreetmap.org/wiki/Railways).
It contains tracks for [passenger and freight trains]() and smaller tracks for [Trams](http://wiki.openstreetmap.org/wiki/Tag:railway%3Dtram) or [similar](http://wiki.openstreetmap.org/wiki/Tag:railway%3Dlight_rail) vehicles. But also tracks for [subways](http://wiki.openstreetmap.org/wiki/Tag:railway%3Dsubway), [narrow-gauge trains](http://wiki.openstreetmap.org/wiki/Tag:railway%3Dnarrow_gauge) or [historic trains](http://wiki.openstreetmap.org/wiki/Tag:railway%3Dpreserved).
Non mainline tracks (marked with class `minor_rail`) used for [storage of trains](http://wiki.openstreetmap.org/wiki/Tag:service%3Dyard) and [maintenance](http://wiki.openstreetmap.org/wiki/Tag:service%3Dsiding) are contained in the highest zoom levels and should be styled more subtle than the mainline tracks with class `rail`.

## Fields

- **class**: Divides the track into mainline tracks (class `rail`) and less important tracks
used for maintenance (class `minor_rail`).
- **subclass**: Original value of the [`railway`](http://wiki.openstreetmap.org/wiki/Key:railway) can be one of
`rail`, `light_rail`, `subway`, `narrow_gauge`, `preserved`, `tram`.
- **properties**: Additional properties describing the nature of tracks. Can be either `bridge` or `tunnel`.

## Mapping

![](mapping.png)


