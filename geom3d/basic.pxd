from libc.math cimport fabs, sqrt

cdef class Vector:
    cdef:
        readonly double x
        readonly double y
        readonly double z

    cpdef Vector cross_product(self, Vector other)
    cpdef double dot_product(self, Vector other)
    cpdef double dot_square(self)
    cpdef Vector update(self, object x= *, object y= *, object z= *)
    cpdef Vector unitize(self)
    cpdef Vector zero_x(self)
    cpdef Vector zero_y(self)
    cpdef Vector zero_z(self)
    cpdef Vector set_x(self, double x)
    cpdef Vector set_y(self, double y)
    cpdef Vector set_z(self, double z)
    cdef bint eq(self, Vector other)
    cpdef Vector copy(self)
    cpdef Vector add(self, Vector other)
    cpdef Vector sub(self, Vector other)
    cpdef Vector mul(self, double other)
    cpdef Vector neg(self)
    cpdef Vector vabs(self)
    cpdef Vector truediv(self, double other)
    cdef double get_length(self)
    cpdef double distance_to(self, Vector other)
    cpdef bint is_zero(self)

    
cpdef inline Vector add(Vector self, Vector other):
    return Vector(self.x + other.x, self.y + other.y, self.z + other.z)

cpdef inline Vector sub(Vector self, Vector other):
    return Vector(self.x - other.x, self.y - other.y, self.z - other.z)

cpdef inline Vector mul(Vector self, double other):
    return Vector(self.x * other, self.y * other, self.z * other)

cpdef inline Vector neg(Vector self):
    return Vector(-self.x, -self.y, -self.z)

cpdef inline Vector vabs(Vector self):
    return Vector(fabs(self.x), fabs(self.y), fabs(self.z))

cpdef inline Vector truediv(Vector self, double other):
    return Vector(self.x / other, self.y / other, self.z / other)

cdef inline double get_length(Vector self):
    return sqrt(self.x * self.x + self.y * self.y + self.z * self.z)

cdef class PointOnLine:
    cdef:
        readonly Line line
        public double length

    cpdef Vector to_vector(self)
    cpdef PointOnLine sub(self, double other)
    cpdef PointOnLine add(self, double other)
    cdef double get_relative_position(self)

cdef class VectorStartStop:
    cdef:
        readonly Vector start
        readonly Vector stop


cdef class Line(VectorStartStop):
    cdef:
        readonly Vector unit_vector
        readonly double length
        readonly Vector stop_sub_start  # a shorthand for self.stop.sub(self.start)

    cpdef double distance_to_line(self, Vector vector)
    cpdef PointOnLine get_point(self, double distance_from_start)
    cpdef PointOnLine get_point_relative(self, double distance_from_start)
    cpdef bint is_colinear(self, Vector vector)
    cpdef Vector get_intersection_point(self, Line other)


cdef class Box(VectorStartStop):

    cpdef bint collides_xy(self, Box other)
    cpdef bint collides(self, Box other)  # type: (Box) -> bool
    cpdef Box translate(self, Vector p)
    cpdef Box relocate_to_zero(self)
    cpdef double get_volume(self)
    cpdef double get_surface_area_xy(self)
    cpdef double get_surface_area(self)
    cdef Vector get_center(self)
    cpdef Box center_at(self, Vector p)
    cdef Vector get_size(self)
    cpdef Line get_diagonal(self)
