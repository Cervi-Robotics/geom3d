import typing as tp

from .path cimport Path

cdef class MakeNonintersectingPaths:
    cdef:
        readonly Path path
        readonly double minimum_flight
        readonly double maximum_flight

    cpdef double get_ceiling_up(self)
    cpdef double get_ceiling_down(self)
    cdef bint eq(self, MakeNonintersectingPaths other)
    cpdef MakeNonintersectingPaths copy(self)


cpdef list make_nonintersecting(list paths)  # type: (tp.List[tp.Tuple[int, int, Path]]) -> tp.List[Path]
cpdef bint are_mutually_nonintersecting(list paths)    # type: (tp.List[Path]) -> bool
