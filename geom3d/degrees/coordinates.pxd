import typing as tp
from geom3d.basic cimport Vector
from .planets cimport Planet


cdef inline double avg(list x):
    cdef double count = 0
    cdef double sum_ = 0.0
    for f in x:
        sum_ += f
        count += 1
    return sum_ / count


cdef class XYPoint:
    cdef:
        double avg_lat
        char is_avg_lat_set     # type: bool
        double x
        double y

    cpdef Coordinates to_coordinates(self, Planet planet=*, object avg_lat=*)
    cpdef double distance(self, object other)  # type: (tp.Union[Vector, XYPoint])

    cpdef Vector to_vector(self)

    cpdef double distance(self, object other)
    cpdef XYPoint add(self, object other)
    cpdef XYPoint sub(self, object other)



cdef class Coordinates:
    cdef:
        double lat
        double lon
