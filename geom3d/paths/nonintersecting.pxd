import typing as tp

from .path cimport Path

cdef class MakeNonintersectingPaths:
    cdef:
        readonly Path path
        readonly double minimum_flight
        readonly double maximum_flight

    cpdef double get_ceiling_up(self)
    cpdef double get_ceiling_down(self)


cpdef list make_nonintersecting(list paths)  # type: (tp.List[tp.Tuple[int, int, Path]]) -> tp.List[Path]
