import itertools
import typing as tp

from geom3d.base cimport iszero, true_modulo, EPSILON
from libc.math cimport fabs
from satella.coding.sequences import add_next, shift

from ..basic cimport Line, Vector, add, sub, mul, neg, PointOnLine
from ..paths import Path


cdef class Polygon2D:
    """
    A polygon that disregards the z axis
    """

    def get_intersection_points(self, other: Line) -> tp.Iterator[Vector]:
        """
        Return all points of intersection between this polygon's perimeter and a given line.

        This will cast the line onto the XY plane first.
        """
        other = other.cast_to_xy_plane()
        cdef:
            Vector p
            Line line

        for line in self.segments:
            p = other.get_intersection_point(line)
            if p:
                yield p

    cpdef Polygon2D downscale(self, double step):
        """
        Make a smaller polygon by moving each vertex by step inside the polygon.

        :param step: distance to which move each vertex
        :raises ValueError: polygon cannot be shrunk further
        """
        cdef:
            PointOnPolygon2D point = self.get_point_on_polygon(0.0)
            list points = []
            Vector candidate_point, vector_ending_at
            double segment_length
            Polygon2D result

        for vector_ending_at, segment_length in zip(shift(self.points, 1), self.len_segments):
            # so that point occurs on the end of n-th segment
            point.advance(segment_length)
            candidate_point = add(vector_ending_at, mul(point.get_unit_vector_towards_polygon(), step))
            if self.contains(candidate_point):
                points.append(candidate_point)
        if len(points) < 3:
            raise ValueError('Polygon cannot be shrunk further!')
        points = points[-1:] + points[:-1]  # since the first point was reported last...
        result = Polygon2D(points)
        return result

    def iter_lengths(self) -> tp.Iterator[float]:
        """
        Return an iterator returning lengths from the start along the perimeter to given vertex of the polygon.
        
        First point is zero.
        """
        cdef:
            double tot_length = 0
            double seg_length

        for seg_length in self.len_segments:
            yield tot_length
            tot_length += seg_length

    def to_path(self, step: float, size: Vector) -> Path:
        """
        Return a path flying around the perimeter of this polygon

        :param step: step to which advance the path with
        :param size: size of the box that will determine the path
        """
        return Path(size, [point for point in self.get_points_along(step, include_last_point=True)])

    def __init__(self, points: tp.List[Vector]):
        cdef:
            Vector p1, p2
            Line x

        if len(points) < 2:
            raise ValueError('At least 3 vertices are needed to construct a polygon')

        self.points = [point.zero_z() for point in points]
        self.segments = []
        for p1, p2 in add_next(points, wrap_over=True):
            self.segments.append(Line(p1, p2))
        self.len_segments = [line.length for line in self.iter_segments()]
        self.total_perimeter_length = sum(self.len_segments)
        self.half_of_shortest_segment = min(x.length for x in self.segments) / 2

    cpdef Line get_segment_at_distance(self, double offset):
        """
        Return the segment backing some distance along the polygon's perimeter

        :param offset: the distance to travel to get the polygon's segment. If this appears directly
            on a vertex, the segment which starts at this vertex will be returned.
        """
        cdef:
            double length_travelled = 0.0
            Line segment

        for segment in itertools.cycle(self.iter_segments()):
            length_travelled += segment.length
            if offset <= length_travelled:
                return segment

    def iter_segments(self) -> tp.Iterator[Line]:
        """
        Get all segments

        :return: an iterator, yielding subsequent segments of this polygon
        """
        cdef Vector point1, point2

        for point1, point2 in add_next(self.points, wrap_over=True):
            yield Line(point1, point2)

    cpdef double get_signed_area(self):
        """Area of this polygon as calculated by the shoelace formula"""
        cdef:
            double sum_ = 0
            Vector p0, p1

        for p0, p1 in add_next(self.points, wrap_over=True):
            sum_ += p0.x * p1.y - p1.x * p0.y
        return sum_ * 0.5

    cpdef double get_surface_area(self):
        """Return the surface area of this polygon"""
        return fabs(self.get_signed_area())

    cdef Vector get_centroid(self):
        cdef:
            double sa = self.get_signed_area()
            double x = 0
            double y = 0
            Vector p0
            Vector p1

        for p0, p1 in add_next(self.points, wrap_over=True):
            x += (p0.x + p1.x) * (p0.x * p1.y - p1.x * p0.y)
            y += (p0.y + p1.y) * (p0.x * p1.y - p1.x * p0.y)
        return Vector(x / 6 * sa, y / 6 * sa)

    @property
    def centroid(self) -> Vector:
        """Return the center of mass for this polygon"""
        return self.get_centroid()

    def iter_from(self, offset: float = 0) -> tp.Iterator[Vector]:
        """
        Return all points that this polygon consists of, but starting from offset

        :param offset: length from start from where to start counting. The next vertex specified
        will come in first. If the offset is directly on a vertex, this vertex will be returned.
        """
        cdef Line first_segment = self.get_segment_at_distance(offset)

        return shift(self.points, self.segments.index(first_segment))

    def __iter__(self) -> tp.Iterator[Vector]:
        """Return all points that this polygon consists of"""
        return iter(self.points)

    cdef bint contains(self, Vector p):
        cdef:
            double max_x = self.points[0].x
            double min_x = self.points[0].x
            double max_y = self.points[0].y
            double min_y = self.points[0].y
            Vector point, next_point, prev_point
            bint inside = False

        for point in self.points[1:]:

            if point.x < min_x:
                min_x = point.x
            elif point.x > max_x:
                max_x = point.x

            if point.y < min_y:
                min_y = point.y
            elif point.y > max_y:
                max_y = point.y

        if (p.x < min_x) or (p.x > max_x) or (p.y < min_y) or (p.y > max_y):
            return False

        for next_point, prev_point in add_next(self, wrap_over=True):
            if (next_point.y > p.y) != (prev_point.y > p.y) and p.x < (
                    prev_point.x - next_point.x) * (p.y - next_point.y) / (
                    prev_point.y - next_point.y) + next_point.x:
                inside = not inside
        return inside

    def __contains__(self, p: Vector) -> bool:
        """Is point p inside polygon?"""
        return self.contains(p)

    cpdef Line get_nth_segment(self, Line segment, int n):
        """Get n-th segment in regards to the one currently passed in"""
        if segment not in self.segments:
            raise ValueError('This segment does not belong in this polygon')
        cdef int index = self.segments.index(segment)
        return self.segments[(index + n) % len(self.segments)]

    cpdef Line get_next_segment(self, Line segment):
        """Return the next segment in regards to the one currently passed"""
        return self.get_nth_segment(segment, +1)

    cpdef Line get_previous_segment(self, Line segment):
        """Return the previous segment in regards to the one currently passed"""
        return self.get_nth_segment(segment, -1)

    cpdef float get_closest_to(self, Vector vec, int iterations = 10):
        """
        Get the length along the perimeter of a perimeter point closest to vec
        
        :param vec: Vector to which returned point on the perimeter of the polygon has to be the closest
        :param iterations: the iterations. The greater the number the slower it runs, but the better the result is
        """
        cdef:
            int i, j
            Line seg
            list sum_of_distances = [(seg.start.distance_to(vec) + seg.stop.distance_to(vec), i) for i, seg in
                                      enumerate(self.iter_segments())]
            int index = min(sum_of_distances)[1]
            Line segment = self.segments[index]
            double cur_ran_start = 0
            double cur_ran_stop = segment.length
            PointOnLine pol1, pol2
            double cur_ran_half

        for j in range(iterations):
            cur_ran_half = (cur_ran_start + cur_ran_stop) / 2
            pol1 = segment.get_point((cur_ran_start + cur_ran_half) / 2)
            pol2 = segment.get_point((cur_ran_stop + cur_ran_half) / 2)
            if pol1.to_vector().distance_to(vec) < pol2.to_vector().distance_to(vec):
                cur_ran_stop = cur_ran_half
            else:
                cur_ran_start = cur_ran_half
        cdef double dist = 0
        for j in range(index):
            dist += self.len_segments[j]
        return dist + cur_ran_half

    cpdef PointOnPolygon2D get_point_on_polygon_relative(self, double distance_from_start,
                                                         double offset = 0):
        """
        Return a point on polygon counted as a fraction of it's total perimeter.

        Eg. 0.5 will get you a point on polygon directly at half of it's perimeter.

        :param distance_from_start: fraction of polygon's total perimeter.
            Must be greater or equal than zero, must be less than 1
        :param offset: offset to use, also a fraction of polygon's total length
        """
        return self.get_point_on_polygon(self.total_perimeter_length * distance_from_start,
                                         self.total_perimeter_length * offset)

    cpdef PointOnPolygon2D get_point_on_polygon(self, double distance_from_start, double offset = 0):
        """
        Return a point somewhere on the perimeter of this polygon

        :param distance_from_start: distance from the first point of this polygon. Can be negative,
            in which case we will count backwards.
        :param offset: offset to add in while calculating the distance. This value is fixed.
        """
        return PointOnPolygon2D(self, distance_from_start, offset)

    def get_points_along(self, step: float,
                         include_last_point: bool = False) -> tp.Iterator[Vector]:
        """
        Return a list of vectors corresponding to equally-spaced points on this line

        :param step: the distance between two consecutive points
        :param include_last_point: whether to include last point. Distance from the almost last to
            last might not be equal to step
        """
        cdef:
            double distance_travelled = 0.0
            PointOnPolygon2D pop = self.get_point_on_polygon(0.0)

        while distance_travelled < self.total_perimeter_length:
            yield pop.to_vector()
            pop.advance(step)
            distance_travelled += step

        if include_last_point:
            yield self.points[-1]


cdef class PointOnPolygon2D:
    """
    A point somewhere on the polygon's perimeter.
    """
    def __init__(self, polygon: Polygon2D, distance_from_start: float, offset: float):
        self.polygon = polygon
        self._distance_from_start = distance_from_start
        self.offset = offset

    @property
    def distance_from_start(self) -> float:
        return self.get_distance_from_start()

    cdef double get_distance_from_start(self):
        return true_modulo(self._distance_from_start + self.offset, self.polygon.total_perimeter_length)

    cpdef bint is_on_vertex(self):  # type: () -> bool
        """Does this point occur right on a vertex of the polygon?"""
        cdef:
            double remaining_distance = self.distance_from_start
            double length

        for length in itertools.cycle(self.polygon.len_segments):
            if iszero(remaining_distance):
                return True
            if remaining_distance < length:
                return False
            remaining_distance -= length

    cpdef void advance(self, double v):
        """
        Move the pointer v ahead.

        The only routine to move inside the polygon at all

        :param v: amount to move the pointer along the perimeter, or a negative value to move
            it backwards.
        """
        self._distance_from_start = true_modulo(self._distance_from_start + v, self.polygon.total_perimeter_length)

    cpdef Vector to_vector(self):
        """
        Returns the coordinates of the point on the perimeter.

        The point will lie precisely on the perimeter
        """
        return self.get_segment_and_vector()[1]

    cpdef tuple get_segment_and_vector(self):
        """
        Return both the vector (as in :func:`~geom3d.polygons.PointOnPolygon2D.to_vector`) and the
        segment on which it lies.

        :return: a tuple of (Line - the segment, Vector - coordinates of this point)
        """
        cdef:
            double remaining_distance = self.distance_from_start
            Line segment
            double seg_length

        for segment, seg_length in zip(self.polygon.iter_segments(), self.polygon.len_segments):
            if seg_length > remaining_distance:
                return segment, segment.get_point(remaining_distance).to_vector()
            else:
                remaining_distance -= seg_length

    cpdef Vector get_unit_vector_towards_polygon(self):
        """
        Get a unit vector, that if applied to self.to_vector() would direct us inside the polygon
        """
        cdef:
            Line segment
            Line prev
            Vector unit_vec
            Vector prev_unit_vec
            Vector common_vec
            Vector vec

        segment, vec = self.get_segment_and_vector()
        if self.is_on_vertex():
            # In that case we have returned the second segment
            prev = self.polygon.get_previous_segment(segment)
            unit_vec = segment.unit_vector
            prev_unit_vec = prev.unit_vector
            common_vec = add(unit_vec, prev_unit_vec).unitize()
        else:
            common_vec = segment.unit_vector

        cdef:
            Vector point = Vector(common_vec.y, -common_vec.x)  # construct orthogonal unit vector
            double epsilon = EPSILON

        cdef Vector point2 = mul(point, epsilon)

        while True:
            if add(vec, point2) in self.polygon:
                return point
            elif sub(vec, point2) in self.polygon:
                return -point
            epsilon *= 0.1
            point2 = mul(point2, 0.1)
            if epsilon < 1E-18:
                raise ValueError('Could not determine, the polygon was too small')


    cpdef Vector get_unit_vector_away_polygon(self):
        """
        Return exactly the opposite vector that
        :func:`~PointOnPolygon2D.get_unit_vector_towards_polygon`
        would return
        """
        return neg(self.get_unit_vector_towards_polygon())
