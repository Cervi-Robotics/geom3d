import logging
import typing as tp
import unittest
logger = logging.getLogger(__name__)

from geom3d.basic import Point, Box


class TestBasic(unittest.TestCase):
    def test_collision(self):
        box1 = Box(Point(0, 0, 0), Point(10, 10, 10))
        box2 = Box(Point(5, 5, 5), Point(15, 15, 15))
        box3 = Box(Point(20, 20, 20), Point(25, 25, 25))
        self.assertTrue(box1.collides(box2))
        self.assertTrue(box2.collides(box1))
        self.assertFalse(box1.collides(box3))
        self.assertFalse(box2.collides(box3))
        self.assertFalse(box3.collides(box1))
        self.assertFalse(box3.collides(box2))




