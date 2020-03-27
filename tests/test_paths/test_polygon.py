import logging
import typing as tp
import unittest

from geom3d import Vector

from geom3d.paths import cover_polygon2d_with_path
from geom3d.polygons import Polygon2D

logger = logging.getLogger(__name__)


class TestPathPolygon(unittest.TestCase):
    def test_path(self):
        poly = Polygon2D([Vector(0, 0), Vector(10, 0), Vector(10, 10), Vector(0, 10)])
        path = cover_polygon2d_with_path(poly, Vector(1, 1), 1, 0.5, 0.0)
