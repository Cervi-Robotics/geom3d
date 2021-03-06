import unittest
import math
from geom3d.paths import Path, MakeNonintersectingPaths, make_nonintersecting
from geom3d import Vector


class TestPath(unittest.TestCase):
    def test_advance_towards(self):
        path = Path(Vector(1, 1), [Vector(0, 0)])
        path.head_towards(Vector(10, 10), 1)
        self.assertEqual(len(path.points), 16)

    def test_get_vector_at(self):
        path = Path(Vector(1, 1), [Vector(0, 0), Vector(1, 0)])
        self.assertEqual(path.get_vector_at(0.5), Vector(0.5, 0))

    def test_insert_vector(self):
        path = Path(Vector(1, 1), [Vector(0, 0), Vector(1, 0), Vector(1, 1)])
        path.insert_at(Vector(2, 2), 0.5)
        self.assertEqual(path.points, [Vector(0, 0), Vector(2, 2), Vector(1, 0), Vector(1, 1)])

        path = Path(Vector(1, 1), [Vector(0, 0), Vector(1, 0), Vector(1, 1)])
        path.insert_at(Vector(2, 2), 1)
        self.assertEqual(path.points, [Vector(0, 0), Vector(2, 2), Vector(1, 1)])

        path = Path(Vector(1, 1), [Vector(0, 0), Vector(1, 0), Vector(1, 1)])
        path.insert_at(Vector(2, 2), 1.5)
        self.assertEqual(path.points, [Vector(0, 0), Vector(1, 0), Vector(2, 2), Vector(1, 1)])

        path = Path(Vector(1, 1), [Vector(0, 0), Vector(1, 0), Vector(1, 1)])
        path.insert_at(Vector(2, 2), 2)
        self.assertEqual(path.points, [Vector(0, 0), Vector(1, 0), Vector(2, 2)])

        path = Path(Vector(1, 1), [Vector(0, 0), Vector(1, 0), Vector(1, 1)])
        path.insert_at(Vector(2, 2), 2.5)
        self.assertEqual(path.points, [Vector(0, 0), Vector(1, 0), Vector(1, 1), Vector(2, 2)])

    def test_simplify(self):
        path1 = Path.from_to(Vector(0, 0), Vector(10, 10), Vector(1, 1), 0.1)
        self.assertEqual(len(path1.simplify().points), 2)

    def test_path(self):
        path1 = Path.from_to(Vector(0, 0), Vector(10, 0), Vector(1, 1), 0.1)
        path2 = Path.from_to(Vector(10, 10), Vector(10, 0), Vector(1, 1), 0.1)
        intersecting_boxes = list(path1.get_intersecting_boxes(path2))
        self.assertGreater(len(intersecting_boxes), 1)

        self.assertTrue(path1.does_collide(path2))

    def test_make_nonintersecting(self):
        p1 = Path.from_to(Vector(0, 0, 2), Vector(10, 10, 2), Vector(1, 1, 1), 0.1)
        p2 = Path.from_to(Vector(5, 5, 2), Vector(15, 15, 2), Vector(1, 1, 1), 0.1)
        self.assertTrue(p1.does_collide(p2))

        m1 = MakeNonintersectingPaths(-5, 10, p1)
        m2 = MakeNonintersectingPaths(-5, 10, p2)
        p1, p2, = make_nonintersecting([m1, m2])
        self.assertFalse(p1.does_collide(p2))

    def test_length(self):
        path1 = Path.from_to(Vector(0, 0), Vector(10, 10), Vector(1, 1), 0.1)
        self.assertAlmostEqual(path1.get_length(), math.sqrt(200), 1)

    def test_reversed(self):
        path1 = Path.from_to(Vector(0, 0), Vector(10, 10), Vector(1, 1), 0.1)
        path2 = path1.reverse()
        self.assertAlmostEqual(path1.get_length(), path2.reverse().get_length(), 2)
