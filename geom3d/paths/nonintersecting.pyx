import logging

from satella.coding.sequences import half_cartesian, even
from .path cimport get_mutual_intersecting, get_still_mutual_intersecting
from .path import get_mutually_intersecting
from ..base cimport isclose
from ..basic cimport Box, Vector

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

    cdef bint eq(self, MakeNonintersectingPaths other):
        return isclose(self.minimum_flight, other.minimum_flight) and \
               isclose(self.maximum_flight, other.maximum_flight) and \
               self.path.eq(other.path)

    def __eq__(self, other: MakeNonintersectingPaths):
        return self.eq(other)

    cpdef MakeNonintersectingPaths copy(self):
        return MakeNonintersectingPaths(self.minimum_flight, self.maximum_flight, self.path.copy())

    def __copy__(self):
        return self.copy()

    def __deepcopy__(self, memo):
        return self.copy()


cdef tuple make_two_blocks_nonintersecting(Box lower, Box higher):  # type: () -> tp.Tuple[Box, Box]
    cdef:
        Vector center_lo = lower.get_center()
        Vector center_hi = higher.get_center()
        Vector size_lo = lower.get_size()
        Vector size_hi = higher.get_size()
        double average_z = (lower.get_center().z+higher.get_center().z) / 2
        double new_lower_z = average_z - size_lo.z / 2 - 0.1
        double new_higher_z = average_z + size_hi.z / 2 + 0.1
    return Box.centered_with_size(center_lo.set_z(new_lower_z), size_lo), \
           Box.centered_with_size(center_hi.set_z(new_higher_z), size_hi)


cdef int make_pair_nonintersecting(MakeNonintersectingPaths lower,
                                   MakeNonintersectingPaths higher) except -1:
    """
    Make a pair of paths nonintersecting
     
    :param lower: path to pull lower on the Z-axis
    :param higher: path to pull higher on the Z-axis
    :raises ValueError: unable to resolve the path such
    """
    cdef:
        set indices_to_pull_lower = set()
        set indices_to_pull_higher = set()
        list lower_points_backup = lower.path.points.copy()
        list higher_points_backup = higher.path.points.copy()
        list ind_lo, ind_hi
        int indic_lo, indic_hi
        Box box1, box2

    get_mutual_intersecting(lower.path, higher.path, indices_to_pull_lower, indices_to_pull_higher)

    while indices_to_pull_lower:

        for indic_lo, indic_hi in get_mutually_intersecting(lower.path, higher.path):
            box1, box2 = make_two_blocks_nonintersecting(lower.path.get_box_at(indic_lo),
                                                         higher.path.get_box_at(indic_hi))
            lower.path.set_box_at(indic_lo, box1)
            higher.path.set_box_at(indic_hi, box2)

            if lower.path[indic_lo].z < lower.minimum_flight:
                lower.path.points = lower_points_backup
                raise ValueError('Cannot pull lower than minimum flight altitude')
            if higher.path[indic_hi].z > higher.maximum_flight:
                higher.path.points = higher_points_backup
                raise ValueError('Cannot pull higher than maximum flight altitude')

        ind_lo = list(indices_to_pull_lower)
        ind_hi = list(indices_to_pull_higher)
        indices_to_pull_lower = set()
        indices_to_pull_higher = set()
        get_still_mutual_intersecting(lower.path, higher.path,
                                      indices_to_pull_lower,
                                      indices_to_pull_higher,
                                      ind_lo, ind_hi)

    return 0


cdef int make_mutually_nonintersecting(MakeNonintersectingPaths a,
                                       MakeNonintersectingPaths b,
                                       bint swap) except -1:
    if a.get_ceiling_down() < a.get_ceiling_up():
        a, b = b, a
    if swap:
        a, b = b, a
    return make_pair_nonintersecting(a, b)


cdef bint _are_mutually_nonintersecting(list paths):  # type: (tp.List[MakeNonintersectingPaths])
    return are_mutually_nonintersecting([path.path for path in paths])


cpdef bint are_mutually_nonintersecting(list paths):
    cdef Path path1, path2
    for path1, path2 in half_cartesian(paths, include_same_pairs=False):
        if path1.does_collide(path2):
            return False
    return True


cpdef list make_nonintersecting(list paths):  # type: (tp.List[MakeNonintersectingPaths]) -> tp.List[Path]
    """
    Make the paths non-intersecting.
    
    This will not modify the argument.

    The preferred z-value will be the first path's first point z value.

    This will be done by adjusting their z-value in place.
    
    Argument is a list of tuple(min_z, max_z, path)
    
    Return will be a list of paths, adjusted so that they are mutually nonintersecting
    
    :param paths: list of MakeNonintersectingPaths, paths to make mutually nonintersecting
    
    :raises ValueError: upon unable to make the paths nonintersecting. 
        This means that your case is non-trivial.
    """
    paths = [path.copy() for path in paths]
    cdef:
        list paths_lower = list(even(paths))
        bint a_higher, b_higher
        MakeNonintersectingPaths elem1, elem2
        bint are_mutual_nonintersection

    if _are_mutually_nonintersecting(paths):
        return [path.path for path in paths]
    are_mutual_nonintersection = False

    while not are_mutual_nonintersection:
        for elem1, elem2 in half_cartesian(paths, include_same_pairs=False):
            if _are_mutually_nonintersecting([elem1, elem2]):
                continue
            a_higher = elem1 not in paths_lower
            b_higher = elem2 not in paths_lower

            try:
                if a_higher == b_higher:
                    make_mutually_nonintersecting(elem1, elem2, False)
                elif a_higher:
                    make_pair_nonintersecting(elem1, elem2)
                else:
                    make_pair_nonintersecting(elem2, elem1)
            except ValueError:
                if a_higher == b_higher:
                    make_mutually_nonintersecting(elem1, elem2, True)
                elif a_higher:
                    make_pair_nonintersecting(elem2, elem1)
                else:
                    make_pair_nonintersecting(elem1, elem2)

        are_mutual_nonintersection = _are_mutually_nonintersecting(paths)

    return [path.path for path in paths]
