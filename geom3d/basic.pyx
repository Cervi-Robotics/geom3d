import logging
import typing as tp

from libc.math cimport fabs

from .base cimport iszero, isclose

logger = logging.getLogger(__name__)

__all__ = ['Vector', 'Box', 'Line', 'PointOnLine']

cdef class Vector:
    """A 3D vector"""
    def __init__(self, x: float, y: float, z: float = 0):
        self.x = x
        self.y = y
        self.z = z

    cpdef double distance_to(self, Vector other):
        """
        Syntactic sugar for
        
        >>> self.sub(other).get_length()
        """
        return self.sub(other).get_length()

    cpdef Vector cross_product(self, Vector other):
        """Calculate the cross product between this vector and the other"""
        return Vector(self.y * other.z - self.z * other.y,
                      self.z * other.y - self.x * other.z,
                      self.x * other.y - self.y * other.z)

    def __hash__(self) -> int:
        return hash(self.x) ^ hash(self.y) ^ hash(self.z)

    cpdef double dot_product(self, Vector other):
        """Calculate the dot product between this vector and the other"""
        return self.x * other.x + self.y * other.y + self.z * other.z

    def __add__(self, other: Vector) -> Vector:
        return add(self, other)

    def __neg__(self) -> Vector:
        return neg(self)

    def __sub__(self, other: Vector) -> Vector:
        return sub(self, other)

    def __truediv__(self, other: float) -> Vector:
        return truediv(self, other)

    def __mul__(self, other: float) -> Vector:
        return mul(self, other)

    def __abs__(self) -> Vector:
        return vabs(self)

    cdef bint eq(self, Vector other):
        return isclose(self.x, other.x) and isclose(self.y, other.y) and \
               isclose(self.z, other.z)

    def __eq__(self, other: Vector) -> bool:
        return self.eq(other)

    cpdef Vector zero_z(self):
        """Return self, but with z coordinate zeroed"""
        return Vector(self.x, self.y, 0)

    @property
    def length(self) -> float:
        return get_length(self)

    cpdef Vector unitize(self):
        """Return an unit vector having the same heading as current vector"""
        cdef double length = self.length
        if length == 0:
            return ZERO_POINT
        return Vector(self.x / length, self.y / length, self.z / length)

    @classmethod
    def zero(cls) -> Vector:
        """Return a (0, 0, 0) point"""
        return ZERO_POINT

    def __str__(self) -> str:
        return f'<{self.x}, {self.y}, {self.z}>'

    def __repr__(self) -> str:
        if iszero(self.z):
            return f'Vector({self.x}, {self.y})'
        else:
            return f'Vector({self.x}, {self.y}, {self.z})'

    cpdef Vector update(self, object x=None, object y=None, object z=None):
        """
        Return this vector, but with some coordinates changed

        :param x: provide a float if x should be changed
        :param y: provide a float if x should be changed
        :param z: provide a float if z should be changed
        :return: new Vector
        """
        return Vector(self.x if x is None else x,
                      self.y if y is None else y,
                      self.z if z is None else z)

    cpdef Vector add(self, Vector other):
        return add(self, other)

    cpdef Vector sub(self, Vector other):
        return sub(self, other)

    cpdef Vector mul(self, double other):
        return mul(self, other)

    cpdef Vector neg(self):
        return neg(self)

    cpdef Vector vabs(self):
        return vabs(self)

    cpdef Vector truediv(self, double other):
        return truediv(self, other)

    cdef double get_length(self):
        return get_length(self)

      
cdef class PointOnLine:
    """
    This class serves to compute points that lie a certain distance from the start, but still
    lie on this line.
    """

    cdef double get_relative_position(self):
        """Get a position 0 >= x >= 1"""
        return self.length / len(self.line.length)

    def __init__(self, line: Line, distance_from_start: float):
        self.line = line
        self.length = distance_from_start % self.line.length

    cpdef PointOnLine add(self, double other):
        return PointOnLine(self.line, self.length + other)

    def __add__(self, other: float) -> PointOnLine:
        return self.add(other)

    cpdef PointOnLine sub(self, double other):
        return PointOnLine(self.line, self.length - other)

    def __sub__(self, other: float) -> PointOnLine:
        return self.sub(other)

    cpdef Vector to_vector(self):
        """Return the physical point given PointOnLine corresponds to"""
        return self.line.start.add(self.line.unit_vector.mul(self.length))

cdef class Line:
    """
    A line in 3D. It starts somewhere and ends somewhere.

    :param start: where does the line start
    :param stop: where does the line end
    """
    cpdef double distance_to_line(self, Vector vector):
        """Return a shortest distance given vector has to an axis defined by this line"""
        return vector.sub(self.start).cross_product(self.stop_sub_start).get_length() / self.stop_sub_start.get_length()

    def __contains__(self, vec: Vector) -> bool:
        """Does this line contain given vector?"""

        cdef double min_x, max_x
        if self.start.x > self.stop.x:
            max_x = self.start.x
            min_x = self.stop.x
        else:
            max_x = self.stop.x
            min_x = self.start.x

        cdef double min_y, max_y
        if self.start.y > self.stop.y:
            max_y = self.start.y
            min_y = self.stop.y
        else:
            max_y = self.stop.y
            min_y = self.start.y

        cdef double min_z, max_z
        if self.start.z > self.stop.z:
            max_z = self.start.z
            min_z = self.stop.z
        else:
            max_z = self.stop.z
            min_z = self.start.z

        if vec.x < min_x:
            return False
        elif vec.y < min_y:
            return False
        elif vec.z < min_z:
            return False
        elif vec.x > max_x:
            return False
        elif vec.y > max_y:
            return False
        elif vec.z > max_z:
            return False

        return self.stop_sub_start.unitize().dot_product(vec.sub(self.stop).unitize()) < 0 and \
               self.start.sub(self.stop).unitize().dot_product(vec.sub(self.start).unitize()) < 0

    def __str__(self) -> str:
        return f'<Line {self.start} {self.stop}>'

    def __init__(self, start: Vector, stop: Vector):
        self.start = start
        self.stop = stop
        self.stop_sub_start = stop.sub(start)
        self.unit_vector = self.stop_sub_start.unitize()
        self.length = self.stop_sub_start.get_length()

    cpdef PointOnLine get_point_relative(self, double distance_from_start):
        """
        get_point() but relative to the entire length of the line
        
        :param distance_from_start: 0 <= x <= 1
        """
        return PointOnLine(self, distance_from_start * self.length)

    cpdef PointOnLine get_point(self, double distance_from_start):
        """
        Get a point that lies on this line some distance from the start

        :param distance_from_start: the distance from the start
        """
        return PointOnLine(self, distance_from_start)

    def get_points_along(self, step: float,
                         include_last_point: bool = False) -> tp.Iterator[Vector]:
        """
        Return a list of vectors corresponding to equally-spaced points on this line

        :param step: next vector will be distant by exactly this from the previous one
        :param include_last_point: whether to include last point. Distance from the almost last to
            last might not be equal to step
        """
        self_length = self.length
        current_distance = 0.0
        while current_distance <= self_length:
            yield self.start.add(self.unit_vector.mul(current_distance))
            current_distance += step

        if include_last_point:
            yield self.stop

    def __eq__(self, other: Line) -> bool:
        return self.start == other.start and self.stop == other.stop

ZERO_POINT = Vector(0, 0, 0)

cdef class Box:
    """
    An axis-aligned box that starts at some place and ends at some place.

    It must occur that:

    >>> start.x < stop.x and start.y < stop.y and start.z < stop.z

    :param start: beginning of this box
    :param stop: end of this box
    """
    def __init__(self, start: Vector, stop: Vector):
        self.start = start
        self.stop = stop

    cpdef bint collides(self, Box other):
        """Does this box share at least one point with the other box?"""
        cdef bint x_cond = self.start.x <= other.start.x <= self.stop.x

        x_cond |= other.start.x <= self.start.x <= other.stop.x
        x_cond |= self.start.x <= other.stop.x <= self.stop.x

        cdef bint y_cond = self.start.y <= other.start.y <= self.stop.y

        y_cond |= other.start.y <= self.start.y <= other.stop.y
        y_cond |= self.start.y <= other.stop.y <= self.stop.y

        cdef bint z_cond = self.start.z <= other.start.z <= self.stop.z

        z_cond |= other.start.z <= self.start.z <= other.stop.z
        z_cond |= self.start.z <= other.stop.z <= self.stop.z

        return x_cond and y_cond and z_cond

    cpdef Box relocate_to_zero(self):
        """Return same sized box, but with starting point at (0, 0, 0)"""
        return self.translate(-self.start)

    cpdef Box translate(self, Vector p):
        """
        Return same box, but translated by given coordinates

        :param p: a vector to translate this box over
        """
        return Box(self.start.add(p), self.stop.add(p))

    @classmethod
    def centered_with_size(cls, center: Vector, size: Vector) -> Box:
        """
        Get a box of a particular _size centered at some point
        :param center: center point
        :param size: _size of the box
        """
        start = center - size / 2
        stop = center + size / 2
        return Box(start, stop)

    @property
    def center(self) -> Vector:
        """Returns the center of this box"""
        return self.get_center()

    cdef Vector get_center(self):
        cdef double x = (self.stop.x - self.start.x) / 2
        cdef double y = (self.stop.y - self.start.y) / 2
        cdef double z = (self.stop.z - self.start.z) / 2
        return Vector(x, y, z)

    cpdef double get_volume(self):
        """Calculate the volume of this box"""
        cdef Vector size = self.get_size()
        return size.x * size.y * size.z

    cpdef double get_surface_area(self):
        """
        Get surface area of this box. This will be the surface area that this box casts onto
        the XY plane
        """
        cdef Vector size = self.get_size()
        return size.x * size.y

    @property
    def size(self) -> Vector:
        """Return the size of this box"""
        return self.get_size()

    cdef Vector get_size(self):
        cdef Vector size = self.stop.sub(self.start)
        cdef double x = size.x
        cdef double y = size.y
        cdef double z = size.z
        return Vector(fabs(x), fabs(y), fabs(z))

    cpdef Box center_at(self, Vector p):
        """Return this box as if centered at point p"""
        return Box.get_centered_with_size(p, self.size)
