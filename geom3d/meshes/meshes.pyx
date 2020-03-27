from libc.math cimport sqrt

import logging
import typing as tp
from ..basic cimport Vector, Line

logger = logging.getLogger(__name__)


cdef class Triangle:
    """
    A triangle defined by it's 3 vertices
    """
    def __init__(self, a: Vector, b: Vector, c: Vector):
        self.a = a
        self.b = b
        self.c = c

    cpdef double get_perimeter_length(self):
        """Return the length of triangle's perimeter"""
        cdef double a
        cdef double b
        cdef double c
        a, b, c = self.get_edges_length()
        return a+b+c

    cpdef list get_edges(self):       # type -> list of Line
        """Return edges of this triangle"""
        return [Line(self.a, self.b), Line(self.b, self.c), Line(self.c, self.a)]

    cpdef object get_edges_length(self):        # type: () -> tp.Tuple[float, float, float]
        """Return lengths of edges corresponding to n-th edge"""
        return (self.a.sub(self.b)).get_length(),\
               (self.b.sub(self.c)).get_length(), \
               (self.c.sub(self.a)).get_length()

    cpdef double get_surface_area(self):
        """Return the surface area of this triangle"""
        cdef:
            double s = self.get_perimeter_length()
            double a, b, c
        a, b, c = self.get_edges_length()
        return sqrt(s*(s-a)*(s-b)*(s-c))

