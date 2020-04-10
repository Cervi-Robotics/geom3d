cpdef list make_nonintersecting(list paths):  # type: (tp.List[tp.Tuple[int, int, Path]]) -> tp.List[Path]
    """
    Make the paths non-intersecting.

    This will be done by adjusting their z-value
    
    Argument is a list of tuple(min_z, max_z, path)
    """
