import typing as tp
from ..basic cimport Vector


cdef class Triangle:
    cdef:
        public Vector a
        public Vector b
        public Vector c

    cpdef object get_edges_length(self):       # type: () -> tp.Tuple[float, float, float]
    cpdef double get_perimeter_length(self)
    cpdef double get_surface_area(self)
    cpdef list get_edges(self)                 # type () -> list of Line


