from geom3d.polygons.__bootstrap__ import bootstrap_cython_submodules
bootstrap_cython_submodules()
from .twodimensional import Polygon2D, PointOnPolygon2D

__all__ = ['Polygon2D', 'PointOnPolygon2D']
