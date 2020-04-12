import typing as tp
from ..basic cimport Vector
from .path cimport Path


cdef object make_pair_nonintersecting(object path1, object path2):
    """
    Make a pair of paths nonintersecting
     
    :type path1: tp.tuple[int, int, Path]
    :type path2: tp.Tuple[int, int, Path]
    :return: tp.Tuple[Path, Path]
    """
    intersecting_boxes_path1 = path1.get_intersecting_boxes(path2)
    intersecting_boxes_path2 = path2.get_intersecting_boxes(path1)

cpdef list make_nonintersecting(list paths):  # type: (tp.List[tp.Tuple[int, int, Path]]) -> tp.List[Path]
    """
    Make the paths non-intersecting.
    
    The preferred z-value will be the first path's first point z value.

    This will be done by adjusting their z-value
    
    Argument is a list of tuple(min_z, max_z, path)
    
    Return will be a list of paths, adjusted so that they are 
    """
    path_with_preferred_z = [(path.points[0], path) for path in paths]

    return