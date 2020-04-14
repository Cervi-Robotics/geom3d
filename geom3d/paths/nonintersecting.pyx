import typing as tp
from ..basic cimport Vector
from .path cimport Path


cdef class MakeNonintersectingPaths:
    def __init__(self, minimum_flight: float, maximum_flight: float, optimum_flight: float,
                 path: Path):
        self.minimum_flight = minimum_flight
        self.maximum_flight = maximum_flight
        self.optimum_flight = optimum_flight
        self.path = path

    cpdef MakeNonintersectingPaths copy(self):
        return MakeNonintersectingPaths(self.minimum_flight, self.maximum_flight,
                                        self.optimum_flight, self.path.copy())


cdef object make_pair_nonintersecting(MakeNonintersectingPaths lower, MakeNonintersectingPaths higher):
    """
    Make a pair of paths nonintersecting
     
    :type path1: tp.tuple[int, int, Path]
    :type path2: tp.Tuple[int, int, Path]
    :return: tp.Tuple[Path, Path]
    """
    lower = lower.copy()
    higher = higher.copy()
    cdef list indices_higher = lower.path.get_intersecting_boxes_indices(higher.path)
    cdef list indices_lower = higher.path.get_intersecting_boxes_indices(higher.path)

cpdef list make_nonintersecting(list paths):  # type: (tp.List[tp.Tuple[int, int, Path]]) -> tp.List[Path]
    """
    Make the paths non-intersecting.
    
    The preferred z-value will be the first path's first point z value.

    This will be done by adjusting their z-value
    
    Argument is a list of tuple(min_z, max_z, path)
    
    Return will be a list of paths, adjusted so that they are mutually nonintersecting
    """
    path_with_preferred_z = [(path.points[0], path) for path in paths]

    return []
