#!/usr/bin/env python3

import os
import sys
import argparse
import fiona
import multiprocessing
from shapely.geometry import shape, mapping
from functools import partial

from label_centerlines import get_centerline

def main(args):

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "input_shp",
        type=str,
        help="input polygons"
        )
    parser.add_argument(
        "output_geojson",
        type=str,
        help="output centerlines"
        )
    parser.add_argument(
        "--segmentize_maxlen",
        type=float,
        help="maximum length used when segmentizing polygon borders",
        default=0.5
        )
    parser.add_argument(
        "--max_points",
        type=int,
        help="number of points per geometry allowed before simplifying",
        default=3000
        )
    parser.add_argument(
        "--simplification",
        type=float,
        help="value which increases simplification when necessary",
        default=0.05
        )
    parser.add_argument(
        "--smooth",
        type=int,
        help="smoothness of the output centerlines",
        default=5
        )
    parser.add_argument(
        "--output_driver",
        type=str,
        help="write to 'ESRI Shapefile' or 'GeoJSON' (default)",
        default="GeoJSON"
    )
    parsed = parser.parse_args(args)
    input_shp = parsed.input_shp
    output_geojson = parsed.output_geojson
    segmentize_maxlen = parsed.segmentize_maxlen
    max_points = parsed.max_points
    simplification = parsed.simplification
    smooth_sigma = parsed.smooth
    driver = parsed.output_driver
    
    with fiona.open(input_shp, "r") as inp_polygons:
        out_schema = inp_polygons.schema.copy()
        out_schema['geometry'] = "LineString"
        with fiona.open(
            output_geojson,
            "w",
            schema=out_schema,
            crs=inp_polygons.crs,
            driver=driver
            ) as out_centerlines:
            pool = multiprocessing.Pool()
            func = partial(
                worker,
                segmentize_maxlen,
                max_points,
                simplification,
                smooth_sigma
            )
            try:
                feature_count = 0
                for feature_name, output in pool.imap_unordered(
                    func,
                    inp_polygons
                    ):
                    feature_count += 1
                    if output:
                        output["properties"]['NAME'] = output["properties"]['NAME']
                        out_centerlines.write(output)
                        print( "Written Feature %s: %s" %(
                            feature_count,
                            feature_name
                            ))
                    else:
                        print("Invalid output for feature", feature_name)
            except KeyboardInterrupt:
                print("Caught KeyboardInterrupt, terminating workers")
                pool.terminate()
            except Exception as e:
                if feature_name:
                    print ("%s: FAILED (%s)" %(feature_name, e))
                else:
                    print ("feature: FAILED (%s)" %(e))
                raise
            finally:
                pool.close()
                pool.join()

def worker(
    segmentize_maxlen,
    max_points,
    simplification,
    smooth_sigma,
    feature
    ):

    geom = shape(feature['geometry'])
    for name_field in ["name", "Name", "NAME"]:
        if name_field in feature["properties"]:
            feature_name = feature["properties"][name_field]
            feature_id = feature["properties"]["OSM_ID"]
            break
        else:
            feature_name = None
    if feature_name:
        print ("Processing: ", feature_name)

    try:
        centerlines_geom = get_centerline(
            geom,
            segmentize_maxlen=segmentize_maxlen,
            max_points=max_points,
            simplification=simplification,
            smooth_sigma=smooth_sigma
            )
    except TypeError as e:
        print (e)
    except:
        raise
    if centerlines_geom:
        return (
            feature_name,
            {
                'properties': feature['properties'],
                'geometry': mapping(centerlines_geom)
            }
        )
    else:
        return (None, None)
    
if __name__ == "__main__":
        main(sys.argv[1:])
