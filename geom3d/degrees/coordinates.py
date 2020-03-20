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
    avg_lat: float  # + is N, - is W, used for transforming to coordinates
    x: float  # computed from longitude, in metres
    y: float  # computed from latitude, in metres
    parent_collection: tp.Optional[XYPointCollection] = None

    def to_coordinates(self, planet: Planet = Earth()) -> Coordinates:
        """Convert back to coordinates"""
        lon_tot_len = 2 * math.pi * planet.radius_at_equator * math.cos(math.radians(self.avg_lat))
        x_to_lon = 360 / lon_tot_len
        y_to_lat = 360 / planet.circumference_at_pole
        return Coordinates(self.x * x_to_lon, self.y * y_to_lat)

    def to_vector(self) -> Vector:
        """Convert self into a vector. The z axis will be set to zero."""
        return Vector(self.x, self.y)

    def distance(self, other: tp.Union[Vector, XYPoint]) -> float:
        """Calculate distance to the other point or vector"""
        return math.sqrt(math.pow(self.x - other.x, 2) + math.pow(self.y, other.y))

    def __add__(self, other: Vector) -> XYPoint:
        return XYPoint(self.avg_lat, self.x + other.x, self.y + other.y)

    def __sub__(self, other: Vector) -> XYPoint:
        return XYPoint(self.avg_lat, self.x - other.x, self.y - other.y)

    def __iadd__(self, other: Vector) -> XYPoint:
        self.x += other.x
        self.y += other.y
        return self

    def __isub__(self, other: Vector) -> XYPoint:
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

    def __init__(self, coords: tp.List[Coordinates], planet: Planet = Earth()):
        if not coords:
            raise ValueError('Specify at least a single coordinate')
        self.planet = planet
        self.avg_lat = avg(coord.lat for coord in coords)
        lon_tot_len = 2 * math.pi * planet.radius_at_equator * math.cos(math.radians(self.avg_lat))
        lon_to_x = lon_tot_len / 360
        lat_to_y = planet.circumference_at_pole / 360
        self.points = [XYPoint(self.avg_lat, lon_to_x * coord.lon,
                               lat_to_y * coord.lat, self) for coord in coords]

        # Calculate maximum error
        pes_lat = max((coord.lat for coord in coords), key=lambda x: abs(x - self.avg_lat))
        lon_at_dev = 2 * math.pi * planet.radius_at_equator * math.cos(math.radians(pes_lat))
        difference = abs(lon_tot_len - lon_at_dev)
        self.maximum_latitudinal_error_per_degree = difference / 360
        diff = abs(pes_lat - self.avg_lat)
        self.maximum_absolute_error = abs(diff) * self.maximum_latitudinal_error_per_degree

    def __getitem__(self, i):
        return self.points[i]

    def __len__(self) -> int:
        return len(self.points)
