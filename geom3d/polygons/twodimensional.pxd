from geom3d.basic cimport Line, Vector


cdef class Polygon2D:
    cdef:
        public list points
        public list segments
        public list len_segments
        public double total_perimeter_length
        public double half_of_shortest_segment

    cdef Vector get_centroid(self)
    cpdef Line get_segment_at_distance(self, double offset)
    cpdef PointOnPolygon2D get_point_on_polygon(self, double distance_from_start, double offset=*)
    cpdef PointOnPolygon2D get_point_on_polygon_relative(self, double distance_from_start,
                                      double offset=*)
    cpdef Line get_next_segment(self, Line segment)
    cpdef Line get_previous_segment(self, Line segment)
    cdef bint contains(self, Vector p)
    cpdef double get_signed_area(self)
    cpdef Line get_nth_segment(self, Line segment, int n)
    cpdef double get_surface_area(self)
    cpdef Polygon2D downscale(self, double step)


cdef class PointOnPolygon2D:
    cdef:
        public Polygon2D polygon
        double _distance_from_start
        double offset

    cpdef bint is_on_vertex(self)
    cpdef void advance(self, double v)
    cpdef Vector to_vector(self)
    cdef double get_distance_from_start(self)
    cpdef Vector get_unit_vector_towards_polygon(self)
    cpdef Vector get_unit_vector_away_polygon(self)
    cpdef object get_segment_and_vector(self)   # type: () -> tp.Tuple[Line, Vector]
