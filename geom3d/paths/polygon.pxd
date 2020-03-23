from geom3d.basic cimport Vector
from geom3d.polygons.twodimensional cimport Polygon2D

from .path import Path


cpdef object cover_polygon2d_with_path(Polygon2D polygon, Vector box, double step_downscale,
                              double step_advance, double start_at)  # type: (...) -> Path

