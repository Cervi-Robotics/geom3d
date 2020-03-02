import logging
import typing as tp
import unittest
logger = logging.getLogger(__name__)

from geom3d.basic import Vector, Box


class TestBasic(unittest.TestCase):
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




