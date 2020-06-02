import typing as tp
from ..basic cimport Vector, Box


cdef class Path:
    cdef:
        public Vector size
        public list points

    cpdef double avg_z(self)
    cpdef Path reverse(self)
    cpdef void set_size(self, Vector value)
    cpdef double get_length(self)
    cpdef int append(self, object elem) except -1  # type: (tp.Union[Box, Vector]) -> None
    cpdef int elevate(self, double height, double delta) except -1      # type: (float, float) - None
    cpdef int head_towards(self, Vector point, double delta) except -1     # type: (Vector, float) -> None
    cpdef int advance(self, Vector delta) except -1        # type: (Vector) -> None
    cpdef Path copy(self)
    cpdef Path simplify(self)
    cpdef list get_intersecting_boxes_indices(self, Path other)
    cpdef Vector get_vector_at(self, double length)
    cpdef void insert_at(self, Vector vector, double length)
    cpdef bint does_collide(self, Path other)
    cpdef Path translate_z(self, double delta)
    cpdef void set_z(self, double new_z)


cpdef void get_mutual_intersecting(Path path1, Path path2, set to_path1, set to_path2)
