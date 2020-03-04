from __future__ import annotations

import itertools
import typing as tp

import math
from satella.coding.sequences import add_next, skip_first, zip_shifted

from ..basic import Line, Vector
from .. import Path
from geom3d import base




class Polygon2D:
    """
    A polygon that disregards the z axis
    """

    def downscale(self, step: float) -> Polygon2D:
        """
        Make a smaller polygon by moving each vertex by step inside the polygon.

        :param step: distance to which move each vertex
        :raises ValueError: polygon cannot be shrunk further
        """
        point = self.get_point_on_polygon(0.0)
        points = []
        for vector, segment_length in zip_shifted((self.points, 1), self.len_segments):
            # so that point occurs on the end of n-th segment
            point.advance(segment_length)
            points.append(vector + point.get_unit_vector_towards_polygon()*step)
        if not all(point in self for point in points):
            raise ValueError('Polygon cannot be shrunk further!')
        points = points[-1:] + points[:-1]      # since the first point was reported last...
        return Polygon2D(points)

    def to_path(self, step: float, size: Vector) -> Path:
        """
        Return a path flying around the perimeter of this polygon

        :param step: step to which advance the path with
        :param size: size of the box that will determine the path
        """
        return Path(size, [point for point in self.get_points_along(step, include_last_point=True)])

    def __init__(self, points: tp.List[Vector]):
        if len(points) < 2:
            raise ValueError('At least 3 vertices are needed to construct a polygon')

        self.points = [point.zero_z() for point in points]
        self.segments = []
        for p1, p2 in add_next(points, wrap_over=True):
            self.segments.append(Line(p1, p2))
        self.len_segments = [line.length for line in self.iter_segments()]
        self.total_perimeter_length = sum(self.len_segments)
        self.half_of_shortest_segment = min(x.length for x in self.segments) / 2

    def iter_segments(self) -> tp.Iterator[Line]:
        """
        Get all segments

        :return: an iterator, yielding subsequent segments of this polygon
        """
        for point1, point2 in add_next(self.points, wrap_over=True):
            yield Line(point1, point2)

    def get_signed_area(self) -> float:
        """Area of this polygon as calculated by the shoelace formula"""
        return 0.5 * sum(p0.x * p1.y - p1.x * p0.y for p0, p1 in add_next(self.points, wrap_over=True))

    def get_surface_area(self) -> float:
        """Return the surface area of this polygon"""
        return abs(self.get_signed_area())

    @property
    def centroid(self) -> Vector:
        """Return the center of mass for this polygon"""
        sa = self.get_signed_area()
        x = sum((p0.x + p1.x) * (p0.x * p1.y - p1.x * p0.y) for p0, p1 in
                add_next(self.points, wrap_over=True)) / (6*sa)
        y = sum((p0.y + p1.y) * (p0.x * p1.y - p1.x * p0.y) for p0, p1 in
                add_next(self.points, wrap_over=True)) / (6*sa)
        return Vector(x, y)

    def __iter__(self) -> tp.Iterator[Vector]:
        """Return all points that this polygon consists of"""
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

    def get_nth_segment(self, segment: Line, n: int) -> Line:
        """Get n-th segment in regards to the one currently passed in"""
        if segment not in self.segments:
            raise ValueError('This segment does not belong in this polygon')
        index = self.segments.index(segment)
        return self.segments[(index + n) % len(self.segments)]

    def get_next_segment(self, segment: Line) -> Line:
        """Return the next segment in regards to the one currently passed"""
        return self.get_nth_segment(segment, +1)

    def get_previous_segment(self, segment: Line) -> Line:
        """Return the previous segment in regards to the one currently passed"""
        return self.get_nth_segment(segment, -1)

    def get_point_on_polygon(self, distance_from_start: float) -> PointOnPolygon2D:
        """
        Return a point somewhere on the perimeter of this polygon

        :param distance_from_start: distance from the first point of this polygon. Can be negative,
            in which case we will count backwards.
        """
        return PointOnPolygon2D(self, distance_from_start)

    def get_points_along(self, step: float,
                         include_last_point: bool = False) -> tp.Iterator[Vector]:
        """
        Return a list of vectors corresponding to equally-spaced points on this line

        :param step: the distance between two consecutive points
        :param include_last_point: whether to include last point. Distance from the almost last to
            last might not be equal to step
        """
        distance_travelled: float = 0.0
        pop = self.get_point_on_polygon(0.0)
        while distance_travelled < self.total_perimeter_length:
            yield pop.to_vector()
            pop.advance(step)
            distance_travelled += step

        if include_last_point:
            yield self.points[-1]


class PointOnPolygon2D:
    """
    This class serves to compute points that lie somewhere on the polygons' perimeter, counting
    as polygon's vertices were specified
    """

    def __init__(self, polygon: Polygon2D, distance_from_start: float):
        self.polygon = polygon
        self.distance_from_start = 0
        self.advance(distance_from_start)

    def is_on_vertex(self) -> bool:
        """Does this point occur right on a vertex of the polygon?"""
        remaining_distance: float = self.distance_from_start
        for length in itertools.cycle(self.polygon.len_segments):
            if math.isclose(remaining_distance, 0, abs_tol=base.EPSILON):
                return True
            if remaining_distance < length:
                return False
            remaining_distance -= length

    def advance(self, v: float):
        """
        Move the pointer v ahead

        :param v: amount to move the pointer along the perimeter, or a negative value to move
            it backwards.
        """
        self.distance_from_start = (self.distance_from_start + v) % \
                                   self.polygon.total_perimeter_length
        if math.isclose(self.distance_from_start, self.polygon.total_perimeter_length,
                        abs_tol=base.EPSILON):
            self.distance_from_start = 0.0

    def to_vector(self) -> Vector:
        """
        Returns the coordinates of the point on the perimeter.

        The point will lie precisely on the perimeter
        """
        return self._get_segment_and_vector()[1]

    def _get_segment_and_vector(self) -> tp.Tuple[Line, Vector]:
        """
        Return both the vector (as in :func:`~geom3d.polygons.PointOnPolygon2D.to_vector`) and the
        segment on which it lies.

        :return: a tuple of (Line - the segment, Vector - coordinates of this point)
        """
        remaining_distance = self.distance_from_start
        for segment, seg_length in zip(self.polygon.iter_segments(), self.polygon.len_segments):
            if seg_length > remaining_distance:
                return segment, segment.get_point(remaining_distance).to_vector()
            else:
                remaining_distance -= seg_length

    def get_unit_vector_towards_polygon(self) -> Vector:
        """
        Get a unit vector, that if applied to self.to_vector() would direct us inside the polygon
        """
        segment, vec = self._get_segment_and_vector()
        if self.is_on_vertex():
            # In that case we have returned the second segment
            prev = self.polygon.get_previous_segment(segment)
            unit_vec = segment.unit_vector
            prev_unit_vec = prev.unit_vector
            common_vec = (unit_vec + prev_unit_vec).unitize()
        else:
            common_vec = segment.unit_vector
        point = Vector(common_vec.y, -common_vec.x)     # construct orthogonal unit vector

        epsilon = base.EPSILON
        while True:
            if vec + (point * epsilon) in self.polygon:
                return point
            elif vec - (point * epsilon) in self.polygon:
                return -point
            epsilon *= 0.1

    def get_unit_vector_away_polygon(self) -> Vector:
        """
        Return exactly the opposite vector that
        :func:`~geom3d.polygons.PointOnPolygon2D.get_unit_vector_towards_polygon`
        would return
        """
        return -self.get_unit_vector_towards_polygon()
