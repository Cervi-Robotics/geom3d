import unittest
from geom3d.paths import Path
from geom3d import Vector


class TestPath(unittest.TestCase):
    def test_advance_towards(self):
        path = Path(Vector(1, 1), [Vector(0, 0)])
        path.head_towards(Vector(10, 10), 1)
        self.assertEqual(len(path.points), 16)

    def test_path(self):
        path1 = Path.from_to(Vector(0, 0), Vector(10, 0), Vector(1, 1), 0.1)
        path2 = Path.from_to(Vector(10, 10), Vector(10, 0), Vector(1, 1), 0.1)
        intersecting_boxes = list(path1.get_intersecting_boxes(path2))
        self.assertGreater(len(intersecting_boxes), 1)
