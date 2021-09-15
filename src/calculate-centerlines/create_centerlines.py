#!/usr/bin/env python

# Author:  Joachim Ungar <joachim.ungar@eox.at>
#
#-------------------------------------------------------------------------------
# Copyright (C) 2015 EOX IT Services GmbH
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies of this Software or works derived from this Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-------------------------------------------------------------------------------

import os
import sys
import argparse
import fiona
import multiprocessing
from shapely.geometry import shape, mapping
from functools import partial

from src_create_centerlines import get_centerlines_from_geom

reload(sys)
sys.setdefaultencoding("utf-8")
print sys.version_info

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
            pool = multiprocessing.Pool(1)
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
                    feature_name = feature_name.encode("utf-8").strip()
                    if output:
                        output["properties"]['NAME'] = output["properties"]['NAME'].encode("utf-8").strip()
                        out_centerlines.write(output)
                        print "written feature %s: %s" %(
                            feature_count,
                            feature_name
                            )
                    else:
                        print "Invalid output for feature", feature_name
            except KeyboardInterrupt:
                print "Caught KeyboardInterrupt, terminating workers"
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
    for name_field in ["NAME"]:
    #for name_field in ["name", "Name", "NAME"]:
        if name_field in feature["properties"]:
            feature_name = feature["properties"][name_field].encode('utf-8')
            feature_id = feature["properties"]["OSM_ID"]
            break
        else:
            feature_name = None
    if feature_name:
        print "processing", feature_name

    try:
        centerlines_geom = get_centerlines_from_geom(
            geom,
            segmentize_maxlen=segmentize_maxlen,
            max_points=max_points,
            simplification=simplification,
            smooth_sigma=smooth_sigma
            )
    except TypeError as e:
        print e
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
