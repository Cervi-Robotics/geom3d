from ..basic cimport Vector

cdef class Path:
    cdef:
        public Vector size
        public list points

    cpdef void set_size(self, Vector value)
    cpdef double get_length(self)
    cpdef Path set_z_to(self, double z)
    cpdef int append(self, object elem) except -1  # type: (tp.Union[Box, Vector]) -> None
    cpdef int elevate(self, height: float, delta: float) except -1      # type: (float, float) - None
    cpdef int head_towards(self, point: Vector, delta: float) except -1     # type: (Vector, float) -> None
    cpdef int advance(self, delta: Vector) except -1        # type: (Vector) -> None
