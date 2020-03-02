from __future__ import annotations

import logging
import typing as tp
from dataclasses import dataclass
from satella.coding import rethrow_as
from satella.coding.structures import Immutable
logger = logging.getLogger(__name__)


__all__ = ['Point', 'Box']


@dataclass
class Point:
    __slots__ = ['x', 'y', 'z']

    x: float
    y: float
    z: float

    def __add__(self, other: Point) -> Point:
        return Point(self.x+other.x, self.y+other.y, self.z+other.z)

    def __sub__(self, other: Point) -> Point:
        return Point(self.x-other.x, self.y-other.y, self.z-other.z)

    def __div__(self, other: float) -> Point:
        return Point(self.x/other, self.y/other, self.z/other)

    def __mul__(self, other: float) -> Point:
        return Point(self.x*other, self.y*other, self.z*other)

    @classmethod
    def zero(cls) -> Point:
        """Return a (0, 0, 0) point"""
        return ZERO_POINT


ZERO_POINT = Point(0, 0, 0)


class Box(Immutable):

    @rethrow_as(AssertionError, ValueError)
    def __init__(self, start: Point, stop: Point):
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
        return Box(Point.zero(), self.stop-self.start)

    def translate(self, p: Point) -> Box:
        """
        Return same box, but translated by given coordinates
        """
        return Box(self.start+p, self.stop+p)

    def center_at(self, p: Point) -> Box:
        """
        Return this box as if centered at point p
        """
        size = self.stop - self.start