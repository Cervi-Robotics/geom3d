from __future__ import annotations

import itertools
import logging
import typing as tp
import warnings

from satella.coding import precondition
from satella.coding.sequences import add_next, skip_first
logger = logging.getLogger(__name__)

from .. import Path
from ..exceptions import ValueWarning

from ..basic import Line, Vector

EPSILON = 0.01


class Polygon2D:
    """
    A polygon that disregards the z axis
    """

    def to_path(self, step: float, size: Vector) -> Path:
        """
        Return a path flying around this polygon
        :param step: step to which advance the path width
        :param size: _size
        :return:
        """
        return Path(size, [point for point in self.get_points_along(step)])

    @precondition(None, 'len(x) > 1')
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

    def get_points_along(self, step: float) -> tp.Iterator[Vector]:
        """
        Return a list of vectors corresponding to equally-spaced points on this line
        """
        pop = self.get_point_on_polygon(0.0)
        while pop.distance_from_start < self.total_perimeter_length:
            yield pop.to_vector()
            pop.advance(step)
        yield self.points[-1]


class PointOnPolygon2D:
    """
    A point somewhere on the polygons' perimeter
    """

    def __init__(self, polygon: Polygon2D, distance_from_start: float):
        self.polygon = polygon

        assert distance_from_start >= 0, "Distance can't be negative!"

        if distance_from_start > self.polygon.total_perimeter_length:
            warnings.warn('Distance too large, wrapping it around the polygon', ValueWarning)
            distance_from_start = distance_from_start % self.polygon.total_perimeter_length

        self.distance_from_start = distance_from_start

    def is_on_vertex(self) -> bool:
        """Does this point occur right on a vertex of the polygon?"""
        remaining_distance: float = self.distance_from_start
        for length in itertools.cycle(self.polygon.len_segments):
            if remaining_distance < length:
                return False
            remaining_distance -= length
            if remaining_distance == 0:
                return True

    def advance(self, v: float):
        """Move the pointer v ahead"""
        self.distance_from_start += v
        if self.distance_from_start > self.polygon.total_perimeter_length:
            self.distance_from_start = self.distance_from_start % self.polygon.total_perimeter_length

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
        point = Vector(unit_vec.y, -unit_vec.x)     # construct orthogonal unit vector

        epsilon = EPSILON
        while True:
            if vec + (point * epsilon) in self.polygon:
                return point
            elif vec - (point * epsilon) in self.polygon:
                return -point
            epsilon *= 0.1

    def get_unit_vector_away_polygon(self) -> Vector:
        return -self.get_unit_vector_towards_polygon()
