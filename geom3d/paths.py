from __future__ import annotations

import logging
import typing as tp
from satella.coding.sequences import half_product
from geom3d.basic import Box, Point

logger = logging.getLogger(__name__)


class Path:
    def __init__(self, elements: tp.List[Box] = None):
        self.elements: tp.List[Box] = elements or []
        self.head: Box = None
        if elements:
            self.head = elements[-1]

    def advance(self, dx: float, dy: float, dz: float):
        """Place next segment of the path at given difference from current head"""
        if dx == 0 and dy == 0 and dz == 0:
            return

        if self.head is None:
            raise ValueError('Path not initialized, at least one element needs to be present!')

        self.head = self.head.translate(Point(dx, dy, dz))
        self.elements.append(self.head)

    def __getitem__(self, item: int) -> Box:
        return self.elements[item]

    def __len__(self) -> int:
        return len(self.elements)

    def __iter__(self) -> tp.Iterator[tp.Box]:
        return iter(self.elements)

    def append(self, box: Box):
        self.elements.append(box)
        self.head = box

    def __contains__(self, item: Box) -> bool:
        """Return if the box item intersects with this path"""
        for elem in self.elements:
            if item.collides(elem):
                return True
        return False

    def get_intersecting_boxes(self, other: Path) -> tp.Generator[tp.Tuple[Box, Box], None, None]:
        """
        Return all intersections of these elements that collide.
        """
        for elem1, elem2 in half_product(self.elements, other.elements):
            if elem1.collides(elem2):
                yield elem1, elem2
