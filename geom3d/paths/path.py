from __future__ import annotations
import warnings
import functools
import typing as tp
from satella.coding.sequences import half_product
from ..basic import Box, Vector, Line
from ..base import iszero
from ..exceptions import ValueWarning, NotReadyError


def must_be_initialized(fun):
    @functools.wraps(fun)
    def inner(self, *args, **kwargs):
        self.head       # raises NotReadyError
        return fun(self, *args, **kwargs)
    return inner


class Path:

    @classmethod
    def from_to(cls, source: Vector, destination: Vector, size: Vector,
                step: tp.Optional[float] = None):
        """
        Get a path from a point to other point with particular _size

        Points will be placed each _size/2 if a vector is given, otherwise each size_of_step distance.
        """
        points = []
        if step is None:
            step = size.length / 2

        for vector in Line(source, destination).get_points_along(step):
            points.append(vector)

        return Path(size, points)

    def __init__(self, size: tp.Optional[Vector] = None,
                 points: tp.Optional[tp.List[Vector]] = None):
        self.points: tp.List[Vector] = points or []
        self.size = size

    @property
    def head(self) -> Vector:
        try:
            return self.points[-1]
        except IndexError:
            raise NotReadyError('Path must contain at least one element')

    def set_size(self, value: Vector):
        self.size = value

    @must_be_initialized
    def advance(self, delta: Vector):
        """Place next segment of the path at given difference from current head"""
        if iszero(delta.length):
            return

        self.points.append(self.head + delta)

    @must_be_initialized
    def head_towards(self, point: Vector, delta: float):
        """
        Place next pieces of the path at delta distances going towards the point. The last
        segment may be shorter

        :param point: point to advance towards
        :param delta: size of step to use in constructing the path
        """
        while point != self.head:
            vector_towards = (point - self.head)
            if vector_towards.length < delta:
                return self.advance(vector_towards)
            self.advance(vector_towards.unitize() * delta)

    def __getitem__(self, item: int) -> Vector:
        return self.points[item]

    def __len__(self) -> int:
        return len(self.points)

    @must_be_initialized
    def __iter__(self) -> tp.Iterator[tp.Box]:
        for point in self.points:
            yield Box.centered_with_size(point, self.size)

    def append(self, elem: tp.Union[Vector, Box]):
        if isinstance(elem, Box):
            box: Box = elem
            if self.size is None:
                self.size = box.size
                center: Vector = box.center
                self.points.append(center)
            else:
                if elem.size != self._size:
                    warnings.warn('Size of next path element differs from the base element. '
                                  'It will be disregarded.', ValueWarning)
                self.points.append(self.head)
        else:
            vector: Vector = elem
            if self._size is None:
                raise ValueError('Path must have at least one Box element!')
            self.points.append(vector)

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
