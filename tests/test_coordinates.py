import geom3d.degrees
import unittest
from geom3d.degrees import XYPointCollection, Coordinates


class TestCoordinates(unittest.TestCase):
    def test_xypoint_collection(self):
        coords = [Coordinates(0.0, 0.3), Coordinates(0.1, 0.2)]
        XYPointCollection(coords)
