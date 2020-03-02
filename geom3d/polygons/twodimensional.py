from __future__ import annotations

import logging
import itertools
import typing as tp
import warnings

from satella.coding.sequences import add_next, skip_first

from geom3d.exceptions import ValueWarning

logger = logging.getLogger(__name__)
from ..basic import Line, Vector, PointInLine

EPSILON = 0.01

class Polygon2D:
    """
    A polygon that disregards the z axis
    """

    def __init__(self, points: tp.List[Vector]):
        self.points = points
        self.len_segments = [line.length for line in self.iter_segments()]
        self.total_perimeter_length = sum(self.len_segments)

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

    def get_point_on_polygon(self, distance_from_start: float) -> PointOnPolygon2D:
        return PointOnPolygon2D(self, distance_from_start)


class PointOnPolygon2D:
    def __init__(self, polygon: Polygon2D, distance_from_start: float, epsilon: tp.Optional[float] = None):
        self.polygon = polygon

        if epsilon is None:
            self.epsilon = EPSILON
        else:
            self.epsilon = epsilon

        if distance_from_start > self.polygon.total_perimeter_length:
            warnings.warn('Distance too big, wrapping it around the polygon', ValueWarning)
            distance_from_start = distance_from_start % self.polygon.total_perimeter_length

        self.distance_from_start = distance_from_start

    def to_vector(self) -> Vector:
        return self._get_segment_and_vector()[1]

    def _get_segment_and_vector(self) -> tp.Tuple[Line, Vector]:
        remaining_distance = self.distance_from_start
        for segment, seg_length in zip(self.polygon.iter_segments(), self.polygon.len_segments):
            if seg_length > remaining_distance:
                return segment, segment.get_point(remaining_distance).to_vector()
            else:
                remaining_distance -= seg_length

    def get_unit_vector_towards_polygon(self) -> Vector:
        segment, vec = self._get_segment_and_vector()
        unit_vec = segment.unit_vector
        point = Vector(unit_vec.y, -unit_vec.x)

        if vec + (point * self.epsilon) in self.polygon:
            return point
        else:
            return -point

    def get_unit_vector_away_polygon(self) -> Vector:
        return -self.get_unit_vector_towards_polygon()
