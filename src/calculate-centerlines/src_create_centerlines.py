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

from shapely.geometry import (
    shape,
    LineString,
    MultiLineString,
    Point,
    MultiPoint,
    mapping
    )
from shapely.wkt import loads
import ogr
from scipy.spatial import Voronoi
import networkx as nx
from itertools import combinations
import numpy as np
from scipy.ndimage import filters
from math import *

debug_output = {}

def get_centerlines_from_geom(
    geometry,
    segmentize_maxlen=0.5,
    max_points=3000,
    simplification=0.05,
    smooth_sigma=5,
    debug=False
    ):
    """
    Returns centerline (for Polygon) or centerlines (for MultiPolygons) as
    LineString or MultiLineString geometries.
    """

    if geometry.geom_type not in ["MultiPolygon", "Polygon"]:
        raise TypeError(
            "Geometry type must be Polygon or MultiPolygon, not %s" %(
                geometry.geom_type
                )
            )

    if geometry.geom_type == "MultiPolygon":
        out_centerlines = MultiLineString([
            get_centerlines_from_geom(subgeom, segmentize_maxlen)
            for subgeom in geometry
            if get_centerlines_from_geom(subgeom, segmentize_maxlen) != None
            ])
        return out_centerlines
    else:

        # Convert Polygon to Linestring.
        if len(geometry.interiors) > 0:
            boundary = geometry.exterior
        else:
            boundary = geometry.boundary

        #print list(boundary.coords)
        if debug:
            debug_output['original_points'] = MultiPoint([
                point
                for point in list(boundary.coords)
            ])

        # Convert to OGR object and segmentize.
        ogr_boundary = ogr.CreateGeometryFromWkb(boundary.wkb)
        ogr_boundary.Segmentize(segmentize_maxlen)
        segmentized = loads(ogr_boundary.ExportToWkt())

        # Get points.
        points = segmentized.coords

        # Simplify segmentized geometry if necessary. This step is required
        # as huge geometries slow down the centerline extraction significantly.
        tolerance = simplification
        while len(points) > max_points:
            # If geometry is too large, apply simplification until geometry
            # is simplified enough (indicated by the "max_points" value)
            tolerance += simplification
            simplified = boundary.simplify(tolerance)
            points = simplified.coords
        if debug:
            debug_output['segmentized_points'] = MultiPoint([
                point
                for point in points
            ])

        # Calculate Voronoi diagram.
        vor = Voronoi(points)
        if debug:
            debug_output['voronoi'] = multilinestring_from_voronoi(
                vor,
                geometry
            )

        # The next three steps are the most processing intensive and probably
        # not the most efficient method to get the skeleton centerline. If you
        # have any recommendations, I would be very happy to know.

        # Convert to networkx graph.
        graph = graph_from_voronoi(vor, geometry)
        graph.edges(18,21)
        # Get end nodes from graph.
        end_nodes = get_end_nodes(graph)
        if len(end_nodes) < 2:
            return None

        # Get longest path.
        longest_paths = get_longest_paths(
            end_nodes,
            graph
            )

        # get least curved path.
        best_path = get_least_curved_path(longest_paths[:5], vor.vertices)

        #print (best_path == longest_paths[0])

        #best_path = longest_paths[0]

        centerline = LineString(vor.vertices[best_path])

        if debug:
            debug_output['centerline'] = centerline

        # Simplify again to reduce number of points.
        # simplified = centerline.simplify(tolerance)
        # centerline = simplified


        # Smooth out geometry.
        centerline_smoothed = smooth_linestring(centerline, smooth_sigma)
        out_centerline = centerline_smoothed
        #print out_centerline
        return out_centerline


def smooth_linestring(linestring, smooth_sigma):
    """
    Uses a gauss filter to smooth out the LineString coordinates.
    """
    smooth_x = np.array(filters.gaussian_filter1d(
        linestring.xy[0],
        smooth_sigma)
        )
    smooth_y = np.array(filters.gaussian_filter1d(
        linestring.xy[1],
        smooth_sigma)
        )
    smoothed_coords = np.hstack((smooth_x, smooth_y))
    smoothed_coords = zip(smooth_x, smooth_y)
    linestring_smoothed = LineString(smoothed_coords)
    return linestring_smoothed


def get_longest_paths(nodes, graph):
    """
    Returns longest path of all possible paths between a list of nodes.
    """
    paths = []
    distances = []
    possible_paths = list(combinations(nodes, r=2))
    for node1, node2 in possible_paths:
        try:
            path = nx.shortest_path(graph, node1, node2, "weight")
        except Exception,e:
            path = []
        if len(path)>1:
            distance = get_path_distance(path, graph)
            paths.append(path)
            distances.append(distance)       
    paths_sorted = [x for (y,x) in sorted(zip(distances, paths), reverse=True)]
    # longest_path = paths_sorted[0]
    # return longest_path
    return paths_sorted


def get_least_curved_path(paths, vertices):

    angle_sums = []
    for path in paths:
        path_angles = get_path_angles(path, vertices)
        angle_sum = abs(sum(path_angles))
        angle_sums.append(angle_sum)
    paths_sorted = [x for (y,x) in sorted(zip(angle_sums, paths))]
    return paths_sorted[0]


def get_path_angles(path, vertices):
    angles = []
    prior_line = None
    next_line = None
    for index, point in enumerate(path):
        if index > 0 and index < len(path)-1:
            prior_point = vertices[path[index-1]]
            current_point = vertices[point]
            next_point = vertices[path[index+1]]
            angles.append(
                get_angle(
                    (prior_point, current_point), (current_point, next_point)
                )
            )

    return angles


def get_angle(line1, line2):
    v1 = line1[0] - line1[1]
    v2 = line2[0] - line2[1]
    angle = np.math.atan2(np.linalg.det([v1,v2]),np.dot(v1,v2))
    return np.degrees(angle)

def get_path_distance(path, graph):
    """
    Returns weighted path distance.
    """
    distance = 0
    for i,w in enumerate(path):
        j=i+1
        if j<len(path):
            #print graph.get_edge_data(path[i],path[j])["weight"]
            #distance += round(graph.edges(path[i],path[j])["weight"], 6)
            distance += round(graph.get_edge_data(path[i],path[j])["weight"], 6)
    return distance


def get_end_nodes(graph):
    """
    Returns list of nodes with just one neighbor node.
    """
#    nodelist = []
#     for i in list(graph.nodes()):
#        if len(list(graph.neighbors(i)))==1:
#            nodelist.append(i)
    nodelist = [
        i
        for i in list(graph.nodes())
        if len(list(graph.neighbors(i)))==1
        ]
    return nodelist


def graph_from_voronoi(vor, geometry):
    """
    Creates a networkx graph out of all Voronoi ridge vertices which are inside
    the original geometry.
    """
    graph = nx.Graph()
    for i in vor.ridge_vertices:
        if i[0]>-1 and i[1]>-1:
            point1 = Point(vor.vertices[i][0])
            point2 = Point(vor.vertices[i][1])
            # Eliminate all points outside our geometry.
            if point1.within(geometry) and point2.within(geometry):
                dist = point1.distance(point2)
                graph.add_nodes_from([i[0], i[1]])
                graph.add_edge(i[0], i[1], weight=dist)
    return graph


def multilinestring_from_voronoi(vor, geometry):
    """
    Creates a MultiLineString geometry out of all Voronoi ridge vertices which
    are inside the original geometry.
    """
    linestrings = []
    for i in vor.ridge_vertices:
        if i[0]>-1 and i[1]>-1:
            point1 = Point(vor.vertices[i][0])
            point2 = Point(vor.vertices[i][1])
            # Eliminate all points outside our geometry.
            if point1.within(geometry) and point2.within(geometry):
                linestring = LineString([point1, point2])
                linestrings.append(linestring)
    multilinestring = MultiLineString(linestrings)
    return multilinestring



if __name__ == "__main__":
        main(sys.argv[1:])
