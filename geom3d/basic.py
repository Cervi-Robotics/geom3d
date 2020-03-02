from __future__ import annotations

import logging
import typing as tp
from dataclasses import dataclass

import math
from satella.coding import rethrow_as
from satella.coding.structures import Immutable
logger = logging.getLogger(__name__)


__all__ = ['Vector', 'Box', 'Line', 'PointInLine']


@dataclass(frozen=True)
class Vector:
    x: float
    y: float
    z: float = 0.0

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


class PointInLine:
    """
    A point on a line
    """
    def __init__(self, line: Line, distance_from_start: float):
        self.line = line
        self.distance_from_start = distance_from_start

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
    start: Vector
    stop: Vector

    def __str__(self) -> str:
        return f'<Line {self.start} {self.stop}>'

    def __post_init__(self):
        super().__setattr__('_unit_vector', (self.stop - self.start).unitize())

    @property
    def unit_vector(self) -> Vector:
        return self._unit_vector

    @property
    def length(self) -> float:
        return (self.stop - self.start).length

    def get_point(self, distance_from_start: float) -> PointInLine:
        return PointInLine(self, distance_from_start)

    def get_points_along(self, step: float) -> tp.Iterator[Vector]:
        """
        Return a list of vectors corresponding to equally-spaced points on this line
        """
        self_length = self.length
        current_distance = 0.0
        while current_distance < self_length:
            yield self.start + (self.unit_vector * current_distance)
            current_distance += step
        yield self.stop


ZERO_POINT = Vector(0, 0, 0)


class Box(Immutable):

    @rethrow_as(AssertionError, ValueError)
    def __init__(self, start: Vector, stop: Vector):
        assert start.x <= stop.x
        assert start.y <= stop.y
        assert start.z <= stop.z
        self.start = start
        self.stop = stop

    def collides(self, other: Box):
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
        """
        Return same sized box, but with starting point at (0, 0, 0)
        """
        return Box(Vector.zero(), self.stop - self.start)

    def translate(self, p: Vector) -> Box:
        """
        Return same box, but translated by given coordinates
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

    @property
    def size(self) -> Vector:
        """Return _size of this box"""
        return abs(self.stop - self.start)

    def center_at(self, p: Vector) -> Box:
        """
        Return this box as if centered at point p
        """
        return Box.get_centered_with_size(p, self.size)