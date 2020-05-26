import logging
import unittest

logger = logging.getLogger(__name__)

from geom3d import Vector, Box, Line


class TestBasic(unittest.TestCase):

    def test_line_intersection(self):
        a = Line(Vector(0, 10, 0), Vector(10, 0, 0))
        b = Line(Vector(0, 0, 0), Vector(10, 10, 0))
        self.assertEqual(a.get_intersection_point(b), Vector(5, 5, 0))

    def test_centered_at(self):
        box = Box(Vector(0, 0, 0), Vector(10, 10, 10))
        self.assertEqual(box.center_at(Vector(0, 0)), Box(Vector(-5, -5, -5), Vector(5, 5, 5)))

    def test_volume_and_surface_area(self):
        box = Box(Vector(1, 4, 3), Vector(4, 7, 6))
        self.assertEqual(box.get_volume(), 27)
        self.assertEqual(box.get_surface_area(), 9 * 6)
        self.assertEqual(box.get_surface_area_xy(), 9)

    def test_collision(self):
        box1 = Box(Vector(0, 0, 0), Vector(10, 10, 10))
        box2 = Box(Vector(5, 5, 5), Vector(15, 15, 15))
        box3 = Box(Vector(20, 20, 20), Vector(25, 25, 25))
        self.assertTrue(box1.collides(box2))
        self.assertTrue(box2.collides(box1))
        self.assertFalse(box1.collides(box3))
        self.assertFalse(box2.collides(box3))
        self.assertFalse(box3.collides(box1))
        self.assertFalse(box3.collides(box2))

    def test_line(self):
        line = Line(Vector(0, 0), Vector(1, 0))
        self.assertEqual(line.unit_vector, Vector(1, 0))

    def test_cross_product(self):
        vec = Vector(3, -3, 1)
        vec2 = Vector(4, 9, 2)
        self.assertEqual(vec.cross_product(vec2), Vector(-15, -2, 39))

    def test_contains(self):
        line = Line(Vector(0, 0), Vector(1, 1))
        self.assertIn(Vector(0.5, 0.5), line)
