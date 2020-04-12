from ..basic cimport Vector
from .path cimport Path


cpdef list make_nonintersecting(list paths):  # type: (tp.List[tp.Tuple[int, int, Path]]) -> tp.List[Path]
    """
    Make the paths non-intersecting.
    
    The preferred z-value will be the first path's first point z value.

    This will be done by adjusting their z-value
    
    Argument is a list of tuple(min_z, max_z, path)
    """
    path_with_preferred_z = [(path.points[0], path) for path in paths]

