import logging
import typing as tp

from libc.math cimport fabs

from .base cimport iszero, isclose

logger = logging.getLogger(__name__)

__all__ = ['Vector', 'Box', 'Line', 'PointOnLine']


cdef class Vector:
    """
    A 3D vector.

    This class is immutable. Use set_* or update() to return an object containing new values

    This is both eq-able and hash-able
    """
    def __init__(self, x: float, y: float, z: float = 0):
        self.x = x
        self.y = y
        self.z = z

    cpdef bint is_zero(self):
        return iszero(self.x) and iszero(self.y) and iszero(self.z)

    cpdef double distance_to(self, Vector other):
        """
        Syntactic sugar for
        
        >>> self.sub(other).get_length()
        """
        return get_length(sub(self, other))

    cpdef Vector cross_product(self, Vector other):
        """Calculate the cross product between this vector and the other"""
        return Vector(self.y * other.z - self.z * other.y,
                      self.z * other.x - self.x * other.z,
                      self.x * other.y - self.y * other.x)

    cdef int hash(self):
        return hash(self.x) ^ hash(self.y) ^ hash(self.z)

    def __hash__(self) -> int:
        return self.hash()

    cpdef double dot_product(self, Vector other):
        """Calculate the dot product between this vector and the other"""
        return self.x * other.x + self.y * other.y + self.z * other.z

    cpdef double dot_square(self):
        """A dot product between this vector and itself"""
        return self.x*self.x + self.y*self.y + self.z*self.z

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
        """
        Syntactic sugar for
        
        >>> vector.update(z=0)
        """
        return Vector(self.x, self.y, 0)

    cpdef Vector zero_y(self):
        """
        Syntactic sugar for
        
        >>> vector.update(y=0)
        """
        return Vector(self.x, 0, self.z)

    cpdef Vector scale_by(self, double factor_x=1, double factor_y=1, double factor_z=1):
        """
        Return this vector by multiplying its coordinates by respective values.
        
        :param factor_x: value to multiply x by 
        :param factor_y: value to multiply y by
        :param factor_z: value to multiply z by
        """
        return Vector(self.x*factor_x, self.y*factor_y, self.z*factor_z)

    cpdef Vector zero_x(self):
        """
        Syntactic sugar for
        
        >>> vector.update(x=0)
        """
        return Vector(0, self.y, self.z)

    @property
    def length(self) -> float:
        return get_length(self)

    cpdef Vector unitize(self):
        """Return an unit vector having the same heading as current vector"""
        cdef double length = self.get_length()
        if iszero(length):
            return Vector(0, 0, 0)
        return Vector(self.x / length, self.y / length, self.z / length)

    cpdef Vector set_x(self, double x):
        """Return self, but with x set to a target value"""
        return Vector(x, self.y, self.z)

    cpdef Vector delta_z(self, double delta_z):
        return Vector(self.x, self.y, self.z + delta_z)

    cpdef Vector set_y(self, double y):
        """Return self, but with y set to a target value"""
        return Vector(self.x, y, self.z)

    cpdef Vector set_z(self, double z):
        """Return self, but with z set to a target value"""
        return Vector(self.x, self.y, z)

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
        """
        Return this vector, but with it's components negated.
        
        Syntactic sugar for:
        
        >>> Vector(-vector.x, -vector.y, -vector.z)
        """
        return neg(self)

    cpdef Vector vabs(self):
        """Return this vector, as constituting of absolute values of it's components.
        
        Syntactic sugar for:
        
        >>> Vector(abs(vector.x), abs(vector.y), abs(vector.z))
        """
        return vabs(self)

    cpdef Vector truediv(self, double other):
        return truediv(self, other)

    cdef double get_length(self):
        return get_length(self)

    # Copying immmutable objects
    def __copy__(self):
        return self

    def __deepcopy__(self, memo):
        return self

      
cdef class PointOnLine:
    """
    This class serves to compute points that lie a certain distance from the start, but still
    lie on this line.

    Immutable.
    """

    def __eq__(self, other: VectorStartStop) -> bool:
        return self.eq(other)

    def __hash__(self) -> int:
        return self.hash()

    cdef int hash(self):
        return hash(self.length) ^ self.line.hash()

    cdef eq(self, PointOnLine other):
        return isclose(self.length, other.length) and self.line.eq(other.line)

    cpdef double get_relative_position(self):
        """Get a position 0 >= x >= 1"""
        return self.length / len(self.line.length)

    def __init__(self, line: Line, distance_from_start: float):
        self.line = line
        self.length = distance_from_start % self.line.length

    cdef PointOnLine add(self, double other):
        return PointOnLine(self.line, (self.length + other) % self.line.length)

    def __add__(self, other: float) -> PointOnLine:
        return self.add(other)

    cdef PointOnLine sub(self, double other):
        return PointOnLine(self.line, (self.length - other) % self.line.length)

    def __sub__(self, other: float) -> PointOnLine:
        return self.sub(other)

    cpdef Vector to_vector(self):
        """Return the physical point given PointOnLine corresponds to"""
        return add(self.line.start, mul(self.line.unit_vector, self.length))

    # Copying immmutable objects
    def __copy__(self):
        return self

    def __deepcopy__(self, memo):
        return self


cdef class VectorStartStop:
    """
    A class having a start and a stop.
    """
    def __init__(self, start: Vector, stop: Vector):
        self.start = start
        self.stop = stop

    def __hash__(self):
        return self.hash()

    cdef int hash(self):
        return self.start.hash() ^ self.stop.hash()

    cdef bint eq(self, VectorStartStop other):
        return self.start.eq(other.start) and self.stop.eq(other.stop)

    def __eq__(self, other: VectorStartStop) -> bool:
        return self.start.eq(other.start) and self.stop.eq(other.stop)

    def copy(self) -> VectorStartStop:
        return self.__class__(self.start, self.stop)

    def __copy__(self):
        return self.copy()

    def __deepcopy__(self, memo):
        return self.copy()

    def __str__(self) -> str:
        return f'<{self.__class__} {self.start} {self.stop}>'

    def __repr__(self) -> str:
        return f'{self.__class__}({self.start}, {self.stop})'

cdef class Line(VectorStartStop):
    """
    A segment in 3D. It starts somewhere and ends somewhere.

    This class is immutable and hashable.

    :param start: where does the line start
    :param stop: where does the line end
    """

    def __init__(self, start: Vector, stop: Vector):
        super().__init__(start, stop)
        self.stop_sub_start = stop.sub(start)
        self.unit_vector = self.stop_sub_start.unitize()
        self.length = self.stop_sub_start.get_length()

    cpdef double distance_to_line(self, Vector vector):
        """Return a shortest distance given vector has to an axis defined by this line"""
        cdef Vector cross_product = vector.sub(self.start).cross_product(vector)
        return cross_product.get_length() / self.length

    cpdef bint is_colinear(self, Vector vector):
        return iszero(vector.sub(self.start).cross_product(self.stop_sub_start).get_length())

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

        return self.unit_vector.dot_product(vec.sub(self.stop).unitize()) < 0 and \
               self.unit_vector.neg().dot_product(vec.sub(self.start).unitize()) < 0

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

    cpdef Line cast_to_xy_plane(self):
        """
        Return self but with Z values set to 0.
        """
        return Line(self.start.zero_z(), self.stop.zero_z())

    cpdef Vector get_intersection_point(self, Line other):
        """        
        :return: a Vector of an intersection point between these two lines, or None else
        """
        cdef:
            Vector da, db, dc, cp_da_db
            double s, t, sq_norm

        da = sub(self.stop, self.start)
        db = sub(other.stop, other.start)
        dc = sub(other.start, self.start)

        cp_da_db = da.cross_product(db)

        sq_norm = cp_da_db.dot_square()

        s = dc.cross_product(db).dot_product(cp_da_db) / sq_norm
        t = dc.cross_product(da).dot_product(cp_da_db) / sq_norm

        if ( 0 <= s <= 1) and (0 <= t <= 1):
            return Vector(self.start.x + da.x * s,
                          self.start.y + da.y * s,
                          self.start.z + da.z * s)


cdef class Box(VectorStartStop):
    """
    An axis-aligned box that starts at some place and ends at some place.

    It must occur that:

    >>> start.x < stop.x and start.y < stop.y and start.z < stop.z

    Otherwise coordinates will be extracted and compared place-wise.

    This class is immutable and hashable.

    :param start: beginning of this box
    :param stop: end of this box
    """
    def __init__(self, start: Vector, stop: Vector):
        cdef double min_x, max_x, min_y, max_y, min_z, max_z
        if start.x > stop.x:
            min_x = stop.x
            max_x = start.x
        else:
            min_x = start.x
            max_x = stop.x

        if start.y > stop.y:
            min_y = stop.y
            max_y = start.y
        else:
            min_y = start.y
            max_y = stop.y

        if start.z > stop.z:
            min_z = stop.z
            max_z = start.z
        else:
            min_z = start.z
            max_z = stop.z

        super().__init__(Vector(min_x, min_y, min_z), Vector(max_x, max_y, max_z))

    cpdef Line get_diagonal(self):
        return Line(self.start, self.stop)

    cpdef bint collides(self, Box other):
        """Does this box share at least one point with the other box?"""

        cdef bint x_cond = check_collision_x(self.start, other.start, self.stop) or \
            check_collision_x(other.start, self.start, other.stop) or \
            check_collision_x(self.start, other.stop, self.stop)

        cdef bint y_cond = check_collision_y(self.start, other.start, self.stop) or \
            check_collision_y(other.start, self.start, other.stop) or \
            check_collision_y(self.start, other.stop, self.stop)

        cdef bint z_cond = check_collision_z(self.start, other.start, self.stop) or \
            check_collision_z(other.start, self.start, other.stop) or \
            check_collision_z(self.start, other.stop, self.stop)

        return x_cond and y_cond and z_cond

    cpdef bint collides_xy(self, Box other):
        """Does this box share at least one point with the other box projected on XY axis?"""

        cdef bint x_cond = check_collision_x(self.start, other.start, self.stop) or \
            check_collision_x(other.start, self.start, other.stop) or \
            check_collision_x(self.start, other.stop, self.stop)

        cdef bint y_cond = check_collision_y(self.start, other.start, self.stop) or \
            check_collision_y(other.start, self.start, other.stop) or \
            check_collision_y(self.start, other.stop, self.stop)

        return x_cond and y_cond

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
        assert size.x >= 0
        assert size.y >= 0
        assert size.z >= 0
        start = center - size / 2
        stop = center + size / 2
        return Box(start, stop)

    @property
    def center(self) -> Vector:
        """Returns the center of this box"""
        return self.get_center()

    cpdef Vector get_center(self):
        """
        Return a vector that appears directly in the center of that box
        """
        return Vector((self.stop.x + self.start.x) / 2,
                      (self.stop.y + self.start.y) / 2,
                      (self.stop.z + self.start.z) / 2)

    cpdef Box center_at(self, Vector p):
        """Return this box as if centered at point p"""
        return Box.centered_with_size(p, self.size)

    @property
    def size(self) -> Vector:
        """Return the size of this box"""
        return self.get_size()

    cdef Vector get_size(self):
        # sorting in the beginning asserts that the difference is positive
        cdef Vector size = self.stop.sub(self.start)
        return Vector(size.x, size.y, size.z)

    cpdef double get_volume(self):
        """Calculate the volume of this box"""
        # sorting in the beginning asserts that the difference is positive
        cdef Vector size = self.get_size()
        return size.x * size.y * size.z

    cpdef double get_surface_area_xy(self):
        """
        Get surface area of this box. This will be the surface area that this box casts onto
        the XY plane
        """
        cdef Vector size = self.get_size()
        return size.x * size.y

    cpdef double get_surface_area(self):
        """
        Get the total surface area of this box
        """
        # sorting in the beginning asserts that the difference is positive

        cdef double line_a = self.stop.x - self.start.x
        cdef double line_b = self.stop.y - self.start.y
        cdef double line_c = self.stop.z - self.start.z

        return (line_a*line_b + line_b*line_c + line_c*line_a) * 2


cdef inline bint check_collision_x(Vector start, Vector mid, Vector stop):
    return start.x <= mid.x <= stop.x


cdef inline bint check_collision_y(Vector start, Vector mid, Vector stop):
    return start.y <= mid.y <= stop.y


cdef inline bint check_collision_z(Vector start, Vector mid, Vector stop):
    return start.z <= mid.z <= stop.z
