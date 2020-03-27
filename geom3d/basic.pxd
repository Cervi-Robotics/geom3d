from libc.math cimport fabs, sqrt

cdef class Vector:
    cdef:
        readonly double x
        readonly double y
        readonly double z

    cpdef Vector cross_product(self, Vector other)
    cpdef double dot_product(self, Vector other)
    cpdef Vector update(self, object x, object y, object z)
    cpdef Vector unitize(self)
    cpdef Vector zero_z(self)
    cdef bint eq(self, Vector other)

    cpdef Vector add(self, Vector other)
    cpdef Vector sub(self, Vector other)
    cpdef Vector mul(self, double other)
    cpdef Vector neg(self)
    cpdef Vector vabs(self)
    cpdef Vector truediv(self, double other)
    cdef double get_length(self)

    cdef inline double distance_to(self, Vector other):
        return self.sub(other).get_length()



cpdef inline Vector add(Vector self, Vector other):
    return Vector(self.x + other.x, self.y + other.y, self.z + other.z)

cpdef inline Vector sub(Vector self, Vector other):
    return Vector(self.x - other.x, self.y - other.y, self.z - other.z)

cpdef inline Vector mul(Vector self, double other):
    return Vector(self.x*other, self.y*other, self.z*other)

cpdef inline Vector neg(Vector self):
    return Vector(-self.x, -self.y, -self.z)

cpdef inline Vector vabs(Vector self):
    return Vector(fabs(self.x), fabs(self.y), fabs(self.z))

cpdef inline Vector truediv(Vector self, double other):
    return Vector(self.x / other, self.y / other, self.z / other)

cdef inline double get_length(Vector self):
    return sqrt(self.x*self.x + self.y*self.y + self.z*self.z)


cdef class PointOnLine:
    cdef:
        readonly Line line
        public double length

    cpdef Vector to_vector(self)
    cpdef PointOnLine sub(self, double other)
    cpdef PointOnLine add(self, double other)
    cdef double get_relative_position(self)


cdef class Line:
    cdef:
        readonly Vector start
        readonly Vector stop
        readonly Vector unit_vector
        readonly double length

    cdef double distance_to_line(self, Vector vector)
    cpdef PointOnLine get_point(self, double distance_from_start)
    cpdef PointOnLine get_point_relative(self, double distance_from_start)


cdef class Box:
    cdef:
        readonly Vector start
        readonly Vector stop

    cpdef bint collides(self, Box other)        # type: (Box) -> bool
    cpdef Box translate(self, Vector p)
    cpdef Box relocate_to_zero(self)
    cpdef double get_volume(self)
    cpdef double get_surface_area(self)
    cdef Vector get_center(self)
    cpdef Box center_at(self, Vector p)
    cdef Vector get_size(self)


