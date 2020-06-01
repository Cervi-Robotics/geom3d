import typing as tp
import logging

from satella.coding.sequences import half_cartesian, even, odd
from satella.coding.structures import HashableWrapper

from ..basic cimport Vector



logger = logging.getLogger(__name__)


cdef class MakeNonintersectingPaths:
    def __init__(self, minimum_flight: float, maximum_flight: float, path: Path):
        self.minimum_flight = minimum_flight
        self.maximum_flight = maximum_flight
        self.path = path

    cpdef double get_ceiling_up(self):
        return self.maximum_flight - self.path.avg_z()

    cpdef double get_ceiling_down(self):
        return self.path.avg_z() - self.minimum_flight


cdef int make_pair_nonintersecting(MakeNonintersectingPaths lower,
                                   MakeNonintersectingPaths higher,
                                   double step) except -1:
    """
    Make a pair of paths nonintersecting
     
    :param lower: path to pull lower on the Z-axis
    :param higher: path to pull higher on the Z-axis
    :param step: a step in Z-axis by which to lower the paths
    :raises ValueError: unable to resolve the path such
    """
    cdef list indices_to_pull_lower, indices_to_pull_higher
    cdef int i

    cdef list lower_points_backup = lower.path.points.copy()
    cdef list higher_points_backup = higher.path.points.copy()

    cdef Vector to_higher = Vector(0, 0, +step)
    cdef Vector to_lower = Vector(0, 0, -step)

    while lower.path.does_collide(higher.path):
        indices_to_pull_lower = lower.path.get_intersecting_boxes_indices(higher.path)
        indices_to_pull_higher = higher.path.get_intersecting_boxes_indices(lower.path)

        for i in indices_to_pull_lower:
            lower.path[i] = lower.path[i].add(to_lower)
            if lower.path[i].z < lower.minimum_flight:
                lower.path.points = lower_points_backup
                raise ValueError('Cannot pull lower than minimum flight')
        for i in indices_to_pull_higher:
            higher.path[i] = higher.path[i].add(to_higher)
            if higher.path[i].z > higher.maximum_flight:
                higher.path.points = higher_points_backup
                raise ValueError('Cannot pull lower than minimum flight')

    return 0


cdef int make_mutually_nonintersecting(MakeNonintersectingPaths a,
                                       MakeNonintersectingPaths b,
                                       bint swap) except -1:
    if a.get_ceiling_down() < a.get_ceiling_up():
        a, b = b, a
    if swap:
        a, b = b, a
    return make_pair_nonintersecting(a, b, 1.0)


cdef bint are_mutually_nonintersecting(list paths):  # type: (tp.List[MakeNonintersectingPaths])
    cdef MakeNonintersectingPaths path1, path2
    for path1, path2 in half_cartesian(paths):
        if path1.path is path2.path:
            continue
        if path1.path.does_collide(path2.path):
            return False
    return True


cpdef list make_nonintersecting(list paths):  # type: (tp.List[MakeNonintersectingPaths]) -> tp.List[Path]
    """
    Make the paths non-intersecting.
    
    The preferred z-value will be the first path's first point z value.

    This will be done by adjusting their z-value in place.
    
    Argument is a list of tuple(min_z, max_z, path)
    
    Return will be a list of paths, adjusted so that they are mutually nonintersecting
    
    :raises ValueError: upon unable to make the paths nonintersecting. 
        This means that your case is non-trivial.
    """
    cdef list paths_lower = list(even(paths))

    cdef bint a_higher, b_higher

    if are_mutually_nonintersecting(paths):
        return [path.path for path in paths]

    cdef MakeNonintersectingPaths elem1, elem2

    while not are_mutually_nonintersecting(paths):
        for elem1, elem2 in half_cartesian(paths, include_same_pairs=False):
            if elem1 == elem2:
                continue
            a_higher = elem1 not in paths_lower
            b_higher = elem2 not in paths_lower

            try:
                if a_higher == b_higher:
                    make_mutually_nonintersecting(elem1, elem2, False)
                elif a_higher:
                    make_pair_nonintersecting(elem1, elem2, 1.0)
                else:
                    make_pair_nonintersecting(elem2, elem1, 1.0)
            except ValueError:
                if a_higher == b_higher:
                    make_mutually_nonintersecting(elem1, elem2, True)
                elif a_higher:
                    make_pair_nonintersecting(elem2, elem1, 1.0)
                else:
                    make_pair_nonintersecting(elem1, elem2, 1.0)

    return [path.path for path in paths]
