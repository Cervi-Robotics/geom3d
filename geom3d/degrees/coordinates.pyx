import collections.abc
import typing as tp

from geom3d.basic cimport Vector
from libc.math cimport cos, M_PI, sqrt, fabs

from .planets import Earth, Planet
from .planets cimport Earth, Planet, to_radians


cdef inline double avg(list x):
    cdef double count = 0
    cdef double sum_ = 0.0
    cdef double f
    for f in x:
        sum_ += f
        count += 1
    return sum_ / count


cdef class XYPoint:
    def __init__(self, avg_lat: tp.Optional[float], x: float, y: float):
        if avg_lat is None:
            self.is_avg_lat_set = False
        else:
            self.is_avg_lat_set = True
            self.avg_lat = avg_lat
        self.x = x
        self.y = y

    cpdef Coordinates to_coordinates(self, Planet planet = Earth(), avg_lat=None):
        cdef double real_avg_lat
        if avg_lat is None:
            if not self.is_avg_lat_set:
                raise ValueError('You must specify average latitude!')
            real_avg_lat = self.avg_lat
        else:
            real_avg_lat = avg_lat

        cdef double lon_tot_len = 2 * M_PI * planet.radius_at_equator * cos(to_radians(real_avg_lat))
        cdef double x_to_lon = 360 / lon_tot_len
        cdef double y_to_lat = 360 / planet.circumference_at_pole
        return Coordinates(self.x * x_to_lon, self.y * y_to_lat)

    @classmethod
    def from_vector(cls, x: Vector) -> XYPoint:
        return XYPoint(x=x.x, y=x.y)

    cpdef Vector to_vector(self):
        """Convert self into a vector. The z axis will be set to zero."""
        return Vector(self.x, self.y)

    cpdef double distance(self, object other):  # type: (tp.Union[Vector, XYPoint])
        """Calculate distance to the other point or vector"""
        cdef double x = self.x - other.x
        x = x * x
        cdef double y = self.y - other.y
        y = y * y
        return sqrt(x + y)

    cpdef XYPoint add(self, object other):
        return XYPoint(None if not self.is_avg_lat_set else self.avg_lat, self.x + other.x,
                       self.y + other.y)

    def __add__(self, other: tp.Union[Vector, XYPoint]) -> XYPoint:
        return self.add(other)

    cpdef XYPoint sub(self, object other):
        return XYPoint(None if not self.is_avg_lat_set else self.avg_lat, self.x - other.x,
                       self.y - other.y)

    def __sub__(self, other: tp.Union[Vector, XYPoint]) -> XYPoint:
        return self.sub(other)

    def __iadd__(self, other: tp.Union[Vector, XYPoint]) -> XYPoint:
        self.x += other.x
        self.y += other.y
        return self

    def __isub__(self, other: tp.Union[Vector, XYPoint]) -> XYPoint:
        self.x -= other.x
        self.y -= other.y
        return self


cdef class Coordinates:
    """
    A position on the surface of the Earth, ignoring the height.

    This is immutable, eq-able and hash-able.
    """
    def __init__(self, lat: float, lon: float):
        self.lat = lat
        self.lon = lon

    def to_xy_point(self, planet: Planet = Earth()) -> XYPoint:
        """
        This will not have any error.

        Although if you wish to convert a series of coordinates, especially in a common
        reference frame, use :class:`geom3d.degrees.XYPointCollection` instead
        """
        return XYPointCollection([self], planet)[0]

    def __eq__(self, other: Coordinates) -> bool:
        return self.lat == other.lat and self.lon == other.lon

    def __hash__(self) -> int:
        return hash(self.lat) ^ hash(self.lon)


class XYPointCollection(collections.abc.Sequence):
    """
    A tool to convert a set of coordinates to (x,y) grid.

    Put here the coordinates which you will consider in a common frame of reference

    This will introduce an error at the x coordinate, amount of which can be calculated from
    :attr:`geom3d.degrees.XYPointCollection.maximum_latitudinal_error_per_degree` and
    :attr:`geom3d.degrees.XYPointCollection.maximum_absolute_error`
    """

    avg_lat: float
    planet: Planet
    maximum_latitudinal_error_per_degree: float  # in metres per degree
    maximum_absolute_error: float  # in metres
    points: tp.List[XYPoint]
    lon_to_x: float
    lat_to_y: float

    def __init__(self, coords: tp.List[Coordinates], planet: Planet = Earth()):
        if not coords:
            raise ValueError('Specify at least a single coordinate')
        self.planet = planet
        self.avg_lat = avg([coord.lat for coord in coords])
        cdef double lon_tot_len = planet.get_circumference_at_latitude(self.avg_lat)
        self.lon_to_x = lon_tot_len / 360
        self.lat_to_y = planet.circumference_at_pole / 360
        self.points = [XYPoint(self.avg_lat, self.lon_to_x * coord.lon,
                               self.lat_to_y * coord.lat, self) for coord in coords]

        # Calculate maximum error
        cdef double pes_lat = max((coord.lat for coord in coords), key=lambda x: abs(x - self.avg_lat))
        cdef double lon_at_dev = planet.get_circumference_at_latitude(pes_lat)
        cdef double difference = fabs(lon_tot_len - lon_at_dev)
        self.maximum_latitudinal_error_per_degree = difference / 360
        cdef double diff = fabs(pes_lat - self.avg_lat)
        self.maximum_absolute_error = fabs(diff) * self.maximum_latitudinal_error_per_degree

    def translate(self, x: Coordinates) -> XYPoint:
        """
        Translate given coordinates using the provided reference frame.

        Also, appends the given point to self.points
        """
        cdef XYPoint xy_point = XYPoint(self.avg_lat, self.lon_to_x * x.lon,
                                        self.lat_to_y * x.lat)
        self.points.append(xy_point)
        return xy_point

    def __getitem__(self, i):
        return self.points[i]

    def __len__(self) -> int:
        return len(self.points)

    def __iter__(self):
        return iter(self.points)

    def to_coordinates(self, v: tp.Union[XYPoint, Vector]) -> Coordinates:
        """
        Convert to coordinates using it's own reference frame
        """
        if isinstance(v, Vector):
            v = XYPoint.from_vector(v)
        return v.to_coordinates(self.planet, self.avg_lat)
