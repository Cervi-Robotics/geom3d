import unittest

from geom3d import Vector
from geom3d.degrees import Coordinates, XYPointCollection
from geom3d.paths import cover_polygon2d_with_path, MakeNonintersectingPaths, make_nonintersecting, \
    are_mutually_nonintersecting
from geom3d.polygons import Polygon2D


class TestNonintersecting(unittest.TestCase):
    """This is far more like an integration test"""

    def test_nonintersecting(self):
        pc = [Coordinates(50.022313, 21.990220),
              Coordinates(50.022935, 21.990492),
              Coordinates(50.021613, 21.991670),
              Coordinates(50.021544, 21.991540),
              Coordinates(50.022149, 21.991335),
              Coordinates(50.021385, 21.992079)]
        xy_pc = XYPointCollection(pc)
        poly1 = Polygon2D([xypoint.to_vector() for xypoint in xy_pc[:3]])
        poly2 = Polygon2D([xypoint.to_vector() for xypoint in xy_pc[3:]])
        path1 = cover_polygon2d_with_path(poly1, Vector(5, 5, 5), 10, 0.3, 0)
        path1.set_z(50)
        path2 = cover_polygon2d_with_path(poly2, Vector(5, 5, 5), 10, 0.3, 0)
        path2.set_z(50)
        make_nonintersecting([MakeNonintersectingPaths(0, 100, path1),
                              MakeNonintersectingPaths(0, 100, path2)])
        self.assertGreater(path2.length, 400)
        self.assertTrue(are_mutually_nonintersecting([path1, path2]))
        path1.simplify()
        path2.simplify()
