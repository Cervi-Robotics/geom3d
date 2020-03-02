import unittest
import typing as tp
from geom3d.polygons import Polygon2D
from geom3d.basic import Vector


class TestPolygon2D(unittest.TestCase):
    def test_point_contains(self):
        poly = Polygon2D([Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 1, 0)])
        self.assertIn(Vector(0.5, 0.5, 0), poly)
        self.assertIn(Vector(0, 0, 0), poly)
        self.assertNotIn(Vector(2, 0.5, 0), poly)
        self.assertNotIn(Vector(2, 2, 0), poly)
