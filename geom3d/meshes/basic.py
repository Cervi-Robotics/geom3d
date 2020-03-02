from __future__ import annotations

from dataclasses import dataclass
import logging
import math
import typing as tp
from ..basic import Vector, Line

logger = logging.getLogger(__name__)


@dataclass
class Triangle:
    """
    A triangle defined by it's 3 vertices
    """
    a: Vector
    b: Vector
    c: Vector

    def get_perimeter_length(self) -> float:
        """Return the length of triangle's perimeter"""
        return sum(self.get_edges_length())

    def get_edges(self) -> tp.Tuple[Line, Line, Line]:
        """Return edges of this triangle"""
        return Line(self.a, self.b), Line(self.b, self.c), Line(self.c, self.a)

    def get_edges_length(self) -> tp.Tuple[float, float, float]:
        """Return lengths of edges corresponding to n-th edge"""
        return (self.a-self.b).length, (self.b-self.c).length, (self.c-self.a).length

    def get_surface_area(self) -> float:
        """Return the surface area of this triangle"""
        s = self.perimeter / 2
        a, b, c = self.get_edges_length()
        return math.sqrt(s*(s-a)*(s-b)*(s-c))
