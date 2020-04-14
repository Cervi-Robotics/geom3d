import typing as tp

from .path cimport Path

cdef class MakeNonintersectingPaths:
    cdef:
        readonly Path path
        readonly double minimum_flight
        readonly double maximum_flight
        readonly double optimum_flight

    cpdef MakeNonintersectingPaths copy(self)


cpdef list make_nonintersecting(list paths)  # type: (tp.List[tp.Tuple[int, int, Path]]) -> tp.List[Path]
