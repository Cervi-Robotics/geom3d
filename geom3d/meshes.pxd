import typing as tp

from .basic cimport Vector, Line

cdef class Ray:
    cdef:
        readonly Vector start
        readonly Vector unit_vector

    cpdef bint collides(self, Triangle triangle)

cdef class Triangle:
    cdef:
        public Vector a
        public Vector b
        public Vector c

    cpdef tuple get_edges_length(self)  # type: () -> tp.Tuple[float, float, float]
    cpdef double get_perimeter_length(self)
    cpdef double get_surface_area(self)
    cpdef tuple get_edges(self)  # type: () -> tp.Tuple[Line, Line, Line]