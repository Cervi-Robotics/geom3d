from __future__ import annotations

import typing as tp
from dataclasses import dataclass
import math
from . import base

from satella.coding.structures import Immutable


__all__ = ['Vector', 'Box', 'Line', 'PointInLine']


@dataclass(frozen=True)
class Vector:
    """A 3D vector"""
    x: float
    y: float
    z: float = 0.0

    def cross_product(self, other: Vector) -> Vector:
        """Calculate the cross product between this vector and the other"""
        return Vector(self.y * other.z - self.z * other.y,
                      self.z * other.y - self.x * other.z,
                      self.x * other.y - self.y * other.z)

    def dot_product(self, other: Vector) -> float:
        """Calculate the dot product between this vector and the other"""
        return self.x * other.x + self.y * other.y + self.z * other.z

    def __add__(self, other: Vector) -> Vector:
        return Vector(self.x + other.x, self.y + other.y, self.z + other.z)

    def __neg__(self) -> Vector:
        return Vector(-self.x, -self.y, -self.z)

    def __sub__(self, other: Vector) -> Vector:
        return Vector(self.x - other.x, self.y - other.y, self.z - other.z)

    def __truediv__(self, other: float) -> Vector:
        return Vector(self.x / other, self.y / other, self.z / other)

    def __mul__(self, other: float) -> Vector:
        return Vector(self.x * other, self.y * other, self.z * other)

    def __abs__(self) -> Vector:
        return Vector(abs(self.x), abs(self.y), abs(self.z))

    def __eq__(self, other: Vector) -> bool:
        return base.isclose(self.x, other.x) and base.isclose(self.y, other.y) and \
               base.isclose(self.z, other.z)

    def zero_z(self) -> Vector:
        """Return self, but with z coordinate zeroed"""
        return Vector(self.x, self.y, 0)

    @property
    def length(self) -> float:
        return math.sqrt(math.pow(self.x, 2)+math.pow(self.y, 2)+math.pow(self.z, 2))

    def unitize(self) -> Vector:
        """Return an unit vector having the same heading as current vector"""
        length: float = self.length
        if length == 0:
            return ZERO_POINT
        return Vector(self.x / length, self.y / length, self.z / length)

    @classmethod
    def zero(cls) -> Vector:
        """Return a (0, 0, 0) point"""
        return ZERO_POINT

    def __str__(self) -> str:
        return f'<{self.x}, {self.y}, {self.z}>'

    def __repr__(self) -> str:
        if base.iszero(self.z):
            return f'Vector({self.x}, {self.y})'
        else:
            return f'Vector({self.x}, {self.y}, {self.z})'


class PointInLine:
    """
    This class serves to compute points that lie a certain distance from the start, but still
    lie on this line.
    """
    def __init__(self, line: Line, distance_from_start: float):
        self.line = line
        self.distance_from_start = distance_from_start % self.line.length

    def __add__(self, other: float) -> PointInLine:
        return PointInLine(self.line, self.distance_from_start + other)

    def __sub__(self, other: float) -> PointInLine:
        return PointInLine(self.line, self.distance_from_start - other)

    def to_vector(self) -> Vector:
        """Return the physical point given PointInLine corresponds to"""
        return self.line.start + (self.line.unit_vector * self.distance_from_start)

    @property
    def length(self) -> float:
        """The distance from the start of the line"""
        return self.distance_from_start


@dataclass(frozen=True)
class Line:
    """
    A line in 3D. It starts somewhere and ends somewhere.

    :param start: where does the line start
    :param stop: where does the line end
    """
    start: Vector
    stop: Vector

    def __str__(self) -> str:
        return f'<Line {self.start} {self.stop}>'

    def __post_init__(self):
        super().__setattr__('_unit_vector', (self.stop - self.start).unitize())
        super().__setattr__('_length', (self.stop - self.start).length)

    @property
    def unit_vector(self) -> Vector:
        """Return a unit vector corresponding to the direction of this line."""
        return self._unit_vector

    @property
    def length(self) -> float:
        """Return the length of this line"""
        return self._length

    def get_point(self, distance_from_start: float) -> PointInLine:
        """
        Get a point that lies on this line some distance from the start

        :param distance_from_start: the distance from the start
        """
        return PointInLine(self, distance_from_start)

    def get_points_along(self, step: float,
                         include_last_point: bool = False) -> tp.Iterator[Vector]:
        """
        Return a list of vectors corresponding to equally-spaced points on this line

        :param step: next vector will be distant by exactly this from the previous one
        :param include_last_point: whether to include last point. Distance from the almost last to
            last might not be equal to step
        """
        self_length = self.length
        current_distance = 0.0
        while current_distance <= self_length:
            yield self.start + (self.unit_vector * current_distance)
            current_distance += step

        if include_last_point:
            yield self.stop


ZERO_POINT = Vector(0, 0, 0)


@dataclass(frozen=True)
class Box(Immutable):
    """
    An axis-aligned box that starts at some place and ends at some place.

    It must occur that:

    >>> start.x < stop.x and start.y < stop.y and start.z < stop.z

    :param start: beginning of this box
    :param stop: end of this box
    """
    start: Vector
    stop: Vector

    def collides(self, other: Box) -> bool:
        """Does this box share at least one point with the other box?"""
        x_cond = self.start.x <= other.start.x <= self.stop.x
        x_cond |= other.start.x <= self.stop.x <= other.stop.x

        x_cond |= other.start.x <= self.start.x <= other.stop.x
        x_cond |= self.start.x <= other.stop.x <= self.stop.x

        y_cond = self.start.y <= other.start.y <= self.stop.y
        y_cond |= other.start.y <= self.stop.y <= other.stop.y

        y_cond |= other.start.y <= self.start.y <= other.stop.y
        y_cond |= self.start.y <= other.stop.y <= self.stop.y

        z_cond = self.start.z <= other.start.z <= self.stop.z
        z_cond |= other.start.z <= self.stop.z <= other.stop.z

        z_cond |= other.start.z <= self.start.z <= other.stop.z
        z_cond |= self.start.z <= other.stop.z <= self.stop.z

        return x_cond and y_cond and z_cond

    def relocate_to_zero(self) -> Box:
        """Return same sized box, but with starting point at (0, 0, 0)"""
        return self.translate(-self.start)

    def translate(self, p: Vector) -> Box:
        """
        Return same box, but translated by given coordinates

        :param p: a vector to translate this box over
        """
        return Box(self.start+p, self.stop+p)

    @classmethod
    def centered_with_size(cls, center: Vector, size: Vector) -> Box:
        """
        Get a box of a particular _size centered at some point
        :param center: center point
        :param size: _size of the box
        """
        start = center - size / 2
        stop = center + size / 2
        return Box(start, stop)

    @property
    def center(self) -> Vector:
        """Returns the center of this box"""
        return (self.stop - self.start) / 2

    def get_volume(self) -> float:
        """Calculate the volume of this box"""
        size = self.size
        return size.x * size.y * size.z

    def get_surface_area(self) -> float:
        """
        Get surface area of this box. This will be the surface area that this box casts onto
        the XY plane
        """
        size = self.size
        return size.x * size.y

    @property
    def size(self) -> Vector:
        """Return the size of this box"""
        return abs(self.stop - self.start)

    def center_at(self, p: Vector) -> Box:
        """Return this box as if centered at point p"""
        return Box.get_centered_with_size(p, self.size)
