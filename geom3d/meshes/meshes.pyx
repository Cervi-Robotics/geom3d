import typing as tp

from libc.math cimport sqrt

from ..basic cimport Vector, Line


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
        return a + b + c

    cpdef object get_edges(self):  # type: () -> tp.Tuple[Line, Line, Line]
        """Return edges of this triangle"""
        return [Line(self.a, self.b), Line(self.b, self.c), Line(self.c, self.a)]

    cpdef object get_edges_length(self):  # type: () -> tp.Tuple[float, float, float]
        """Return lengths of edges corresponding to n-th edge"""
        return self.a.distance_to(self.b), self.b.distance_to(self.c), \
               self.c.distance_to(self.b)

    cpdef double get_surface_area(self):
        """Return the surface area of this triangle"""
        cdef double s = self.get_perimeter_length()
        cdef double a, b, c
        a, b, c = self.get_edges_length()
        return sqrt(s * (s - a) * (s - b) * (s - c))
