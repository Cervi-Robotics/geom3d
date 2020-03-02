import unittest
import logging
import typing as tp
import sys
from geom3d import Path, Vector
from geom3d.polygons import Polygon2D


logger = logging.getLogger(__name__)


class TestPolygon2D(unittest.TestCase):
    def test_point_contains(self):
        poly = Polygon2D([Vector(0, 0, 0), Vector(1, 0, 0), Vector(1, 1, 0)])
        self.assertIn(Vector(0.5, 0.5, 0), poly)
        self.assertIn(Vector(0, 0, 0), poly)
        self.assertNotIn(Vector(2, 0.5, 0), poly)
        self.assertNotIn(Vector(2, 2, 0), poly)

    def test_get_unit_vector_towards_polygon(self):
        poly = Polygon2D([Vector(0, 0), Vector(10, 0), Vector(10, 10), Vector(0, 10)])
        self.assertEqual(poly.total_perimeter_length, 40)
        self.assertEqual(poly.len_segments, [10, 10, 10, 10])
        point = poly.get_point_on_polygon(5)
        self.assertEqual(point.to_vector(), Vector(5, 0))
        self.assertEqual(point.get_unit_vector_towards_polygon(), Vector(0, 1))
        self.assertEqual(point.get_unit_vector_away_polygon(), Vector(0, -1))
        point = poly.get_point_on_polygon(-5)
        self.assertEqual(point.to_vector(), Vector(0, 5))
        self.assertEqual(point.get_unit_vector_towards_polygon(), Vector(1, 0))

    def test_to_path(self):
        poly = Polygon2D([Vector(0, 0), Vector(10, 0), Vector(10, 10), Vector(0, 10)])
        path1 = poly.to_path(0.1, Vector(1, 1))
        path2 = Path.from_to(Vector(0, 0), Vector(10, 0), Vector(1, 1), 0.1)
        intersects = list(path1.get_intersecting_boxes(path2))
        self.assertGreater(len(intersects), 1)