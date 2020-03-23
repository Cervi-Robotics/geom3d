from __future__ import annotations

import logging
import math
import collections.abc
import typing as tp
from dataclasses import dataclass

from .planets import Earth, Planet
from ..basic import Vector

logger = logging.getLogger(__name__)


@dataclass
class XYPoint:
    avg_lat: tp.Optional[float] = None  # + is N, - is W, used for transforming to coordinates
    x: float  # computed from longitude, in metres
    y: float  # computed from latitude, in metres
    parent_collection: tp.Optional[XYPointCollection] = None

    def to_coordinates(self, planet: Planet = Earth(), avg_lat: tp.Optional[float] = None) -> Coordinates:
        """Convert back to coordinates"""
        if avg_lat is None:
            if self.avg_lat is None:
                raise ValueError('You must specify average latitude!')
            avg_lat = self.avg_lat

        lon_tot_len = 2 * math.pi * planet.radius_at_equator * math.cos(math.radians(avg_lat))
        x_to_lon = 360 / lon_tot_len
        y_to_lat = 360 / planet.circumference_at_pole
        return Coordinates(self.x * x_to_lon, self.y * y_to_lat)

    @classmethod
    def from_vector(cls, x: Vector) -> XYPoint:
        return XYPoint(x=x.x, y=x.y)

    def to_vector(self) -> Vector:
        """Convert self into a vector. The z axis will be set to zero."""
        return Vector(self.x, self.y)

    def distance(self, other: tp.Union[Vector, XYPoint]) -> float:
        """Calculate distance to the other point or vector"""
        return math.sqrt(math.pow(self.x - other.x, 2) + math.pow(self.y, other.y))

    def __add__(self, other: tp.Union[Vector, XYPoint]) -> XYPoint:
        return XYPoint(self.avg_lat, self.x + other.x, self.y + other.y)

    def __sub__(self, other: tp.Union[Vector, XYPoint]) -> XYPoint:
        return XYPoint(self.avg_lat, self.x - other.x, self.y - other.y)

    def __iadd__(self, other: tp.Union[Vector, XYPoint]) -> XYPoint:
        self.x += other.x
        self.y += other.y
        return self

    def __isub__(self, other: tp.Union[Vector, XYPoint]) -> XYPoint:
        self.x -= other.x
        self.y -= other.y
        return self


@dataclass
class Coordinates:
    lat: float  # + is N, - is W
    lon: float  # + is E, - is W

    def to_xy_point(self, planet: Planet = Earth()) -> XYPoint:
        """
        This will not have any error.

        Although if you wish to convert a series of coordinates, especially in a common
        reference frame, use :class:`geom3d.degrees.XYPointCollection` instead
        """
        return XYPointCollection([self], planet)[0]


def avg(x: tp.Iterable[float]) -> float:
    count = 0
    sum_ = 0.0
    for f in x:
        sum_ += f
        count += 1
    return sum_ / count


@dataclass
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
        self.avg_lat = avg(coord.lat for coord in coords)
        lon_tot_len = 2 * math.pi * planet.radius_at_equator * math.cos(math.radians(self.avg_lat))
        self.lon_to_x = lon_tot_len / 360
        self.lat_to_y = planet.circumference_at_pole / 360
        self.points = [XYPoint(self.avg_lat, self.lon_to_x * coord.lon,
                               self.lat_to_y * coord.lat, self) for coord in coords]

        # Calculate maximum error
        pes_lat = max((coord.lat for coord in coords), key=lambda x: abs(x - self.avg_lat))
        lon_at_dev = 2 * math.pi * planet.radius_at_equator * math.cos(math.radians(pes_lat))
        difference = abs(lon_tot_len - lon_at_dev)
        self.maximum_latitudinal_error_per_degree = difference / 360
        diff = abs(pes_lat - self.avg_lat)
        self.maximum_absolute_error = abs(diff) * self.maximum_latitudinal_error_per_degree

    def translate(self, x: Coordinates) -> XYPoint:
        """
        Translate given coordinates using the provided reference frame.

        Also, appends the given point to self.points
        """
        xy_point = XYPoint(self.avg_lat, self.lon_to_x * x.lon,
                           self.lat_to_y * x.lat)
        self.points.append(xy_point)
        return xy_point

    def __getitem__(self, i):
        return self.points[i]

    def __len__(self) -> int:
        return len(self.points)

    def to_coordinates(self, v: tp.Union[XYPoint, Vector]) -> Coordinates:
        """
        Convert to coordinates using it's own reference frame
        """
        if isinstance(v, Vector):
            v = XYPoint.from_vector(v)
        return v.to_coordinates(self.planet, self.avg_lat)
