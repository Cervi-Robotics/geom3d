from libc.math cimport fabs

cdef public double EPSILON

cpdef inline bint isclose(double a, double b):
    return fabs(a-b) < EPSILON

cpdef inline bint iszero(double a):
    return fabs(a) < EPSILON

cpdef void set_epsilon(double new_epsilon)
cpdef double true_modulo(double a, double b)
