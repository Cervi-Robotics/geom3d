from geom3d.basic cimport Vector
from geom3d.polygons.twodimensional cimport Polygon2D

from .path cimport Path


cpdef Path cover_polygon2d_with_path(Polygon2D polygon, Vector box, double step_downscale,
                                     double step_advance, double start_at, int limit_threes = 200):
    """Build a path covering the entire polygon. This will try to build a spiral with flat down
    advancements at the end of each perimeter.

    The path will start at the outer rim of the polygon and will travel inwards.

    :param polygon: polygon to calculate tha path for
    :param box: size of the box to use in the returned path
    :param step_downscale: step by which the polygon be decreased each fly-around
    :param step_advance: steps to use in constructing the path
    :param start_at: fraction (0 <= x < 0) of total polygon's perimeter length to start the path at
    :return: path that covers the entire polygon
    """
    cdef:
        double offset = polygon.total_perimeter_length * start_at
        Path path = Path(box, [polygon.get_point_on_polygon(offset).to_vector()])
        Vector point
        int number_threes = 0

    while True:
        for point in polygon.iter_from(start_at * polygon.total_perimeter_length):
            path.head_towards(point, step_advance)
        path.head_towards(polygon.get_point_on_polygon(offset).to_vector(), step_advance)
        try:
            polygon = polygon.downscale(step_downscale)
        except ValueError:
            return path
        if len(polygon.points) == 3:
            number_threes += 1
        if number_threes == limit_threes:
            return path
        offset = polygon.total_perimeter_length * start_at
        path.head_towards(polygon.get_point_on_polygon(offset).to_vector(), step_advance)
