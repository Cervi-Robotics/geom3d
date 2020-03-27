from libc.math cimport M_PI


cdef inline double to_radians(double degrees):
    return degrees * (M_PI / 180.0)


cdef class Planet:
    """
    This should have two class properties:

    * `radius_at_equator` -
    """
    cdef:
        public double circumference_at_pole
        public radius_at_equator

    cpdef double get_circumference_at_latitude(self, double latitude)


cdef class Earth(Planet):
    pass
