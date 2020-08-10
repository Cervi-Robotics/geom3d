import geom3d.degrees
import unittest


class TestCoordinates(unittest.TestCase):
    def test_xypoint_collection(self):
        coords = [geom3d.degrees.Coordinates(0.0, 0.3), geom3d.degrees.Coordinates(0.1, 0.2)]
        geom3d.degrees.XYPointCollection(coords)
