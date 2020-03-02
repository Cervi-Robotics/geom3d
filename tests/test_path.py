import unittest
import typing as tp
from geom3d import Path, Vector


class TestPath(unittest.TestCase):
    def test_path(self):
        path1 = Path.from_to(Vector(0, 0), Vector(10, 0), Vector(1, 1), 0.1)
        path2 = Path.from_to(Vector(10, 10), Vector(10, 0), Vector(1, 1), 0.1)
        intersecting_boxes = list(path1.get_intersecting_boxes(path2))
        self.assertGreater(len(intersecting_boxes), 1)
