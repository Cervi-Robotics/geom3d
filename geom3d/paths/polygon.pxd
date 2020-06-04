from geom3d.basic cimport Vector
from geom3d.polygons.twodimensional cimport Polygon2D
from geom3d.paths.path cimport Path


cpdef Path cover_polygon2d_with_path(Polygon2D polygon, Vector box, double step_downscale,
                                     double step_advance, double start_at, int limit_threes = *)
