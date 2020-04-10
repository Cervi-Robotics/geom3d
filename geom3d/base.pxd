from libc.math cimport fabs

# EPSILON is to be set via set_epsilon
cdef public double EPSILON

cdef inline bint isclose(double a, double b):
    return fabs(a - b) < EPSILON

cdef inline bint iszero(double a):
    return fabs(a) < EPSILON

cpdef void set_epsilon(double new_epsilon)
cdef double true_modulo(double a, double b)
