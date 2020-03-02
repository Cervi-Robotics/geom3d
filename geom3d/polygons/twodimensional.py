import logging
import itertools
import typing as tp

from satella.coding.sequences import add_next, skip_first

logger = logging.getLogger(__name__)
from ..basic import Line, Vector


class Polygon2D:
    """
    A polygon that disregards the z axis
    """

    def __init__(self, points: tp.List[Vector]):
        self.points = points

    def iter_segments(self) -> tp.Iterator[Line]:
        """Get all segments"""
        for point1, point2 in add_next(self.points, wrap_over=True):
            yield Line(point1, point2)

    def get_surface_area(self) -> float:
        return 0.5 * abs(sum(p0.x * p1.y - p1.x * p0.y
                             for p0, p1 in add_next(self.points, wrap_over=True)))

    def __iter__(self) -> tp.Iterator[Vector]:
        return iter(self.points)

    def __contains__(self, p: Vector) -> bool:
        """Is point p inside polygon?"""
        max_x = min_x = self.points[0].x
        max_y = min_y = self.points[0].y

        for point in skip_first(self, 1):
            min_x = min(min_x, point.x)
            max_x = max(max_x, point.x)
            min_y = min(min_y, point.y)
            max_y = max(max_y, point.y)

        if (p.x < min_x) or (p.x > max_x) or (p.y < min_y) or (p.y > max_y):
            return False

        inside: bool = False
        for next_point, prev_point in add_next(self, wrap_over=True):
            if (next_point.y > p.y) != (prev_point.y > p.y) and p.x < (
                    prev_point.x - next_point.x) * (p.y - next_point.y) / (
                    prev_point.y - next_point.y) + next_point.x:
                inside = not inside
        return inside
