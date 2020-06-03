import typing as tp

from geom3d.basic cimport Vector

from .planets cimport Planet


cdef class XYPoint:
    cdef:
        double avg_lat
        bint is_avg_lat_set  # type: bool
        double x
        double y

    cpdef Coordinates to_coordinates(self, Planet planet= *, object avg_lat= *)
    cpdef double distance(self, object other)  # type: (tp.Union[Vector, XYPoint])

    cpdef Vector to_vector(self)

    cpdef double distance(self, object other)       # to be returned in meters
    cpdef XYPoint add(self, object other)
    cpdef XYPoint sub(self, object other)

    cdef int hash(self)
    cdef bint eq(self, XYPoint other)


cdef class Coordinates:
    cdef:
        readonly double lat
        readonly double lon

    cpdef XYPoint to_xy_point(self, Planet planet= *)
    cdef bint eq(self, Coordinates other)
    cdef int hash(self)


cdef class XYPointCollection:
    cdef:
        public double avg_lat
        public Planet planet
        public double maximum_latitudinal_error_per_degree
        public double maximum_absolute_error    # in metres
        public list points      # type: tp.List[XYPoint]
        public double lon_to_x
        public double lat_to_y

    cpdef XYPoint translate(self, Coordinates x)
