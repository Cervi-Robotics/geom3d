from __future__ import annotations

import logging
import warnings
import functools
import typing as tp
from satella.coding.sequences import half_product
from .basic import Box, Vector
from .exceptions import ValueWarning

logger = logging.getLogger(__name__)


def must_be_initialized(fun):
    @functools.wraps(fun)
    def inner(self, *args, **kwargs):
        if self.head is None:
            raise ValueError('Path must contain at least one element')
        return fun(self, *args, **kwargs)
    return inner


class Path:
    def __init__(self, elements: tp.List[Box] = None):
        self.size: tp.Optional[Vector] = None
        self.points: tp.List[Vector] = []
        self.head: tp.Optional[Vector] = None
        if elements:
            self.box = elements[-1].size
            self.points = [box.center for box in elements]

    @must_be_initialized
    def advance(self, delta: Vector):
        """Place next segment of the path at given difference from current head"""
        if len(delta) == 0:
            return

        self.head = self.head + delta
        self.elements.append(self.head)

    def __getitem__(self, item: int) -> Vector:
        return self.elements[item]

    def __len__(self) -> int:
        return len(self.elements)

    @must_be_initialized
    def __iter__(self) -> tp.Iterator[tp.Box]:
        for point in self.elements:
            yield Box.centered_with_size(point, self.size)

    def append(self, elem: tp.Union[Vector, Box]):
        if isinstance(elem, Box):
            box: Box = elem
            if self.size is None:
                self.size = box.size
                center: Vector = box.center
                self.elements.append(center)
                self.head = center
            else:
                if elem.size != self.size:
                    warnings.warn('Size of next path element differs from the base element. '
                                  'It will be disregarded.', ValueWarning)
                self.head = elem.center
                self.elements.append(self.head)
        else:
            vector: Vector = elem
            if self.size is None:
                raise ValueError('Path must have at least one Box element!')
            self.elements.append(vector)
            self.head = vector

    def __contains__(self, item: Box) -> bool:
        """Return if the box item intersects with this path"""
        for box in self:
            if item.collides(box):
                return True
        return False

    def get_intersecting_boxes(self, other: Path) -> tp.Generator[tp.Tuple[Box, Box], None, None]:
        """
        Return all intersections of these elements that collide.
        """
        for elem1, elem2 in half_product(self, other):
            if elem1.collides(elem2):
                yield elem1, elem2
