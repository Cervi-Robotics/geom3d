import typing as tp
import warnings
from copy import copy
from satella.coding.sequences import half_product, add_next, count

from ..base cimport iszero, isclose
from ..basic cimport Box, Vector, Line
from ..exceptions import ValueWarning, NotReadyError


cdef class Path:
    cpdef Path reverse(self):
        """Return this path, but backwards"""
        return Path(self.size, list(reversed(self.points)))

    cpdef Path set_z_to(self, double z):
        """
        Change the z of every vector to that provided.

        :param z: new z to set for every vector

        :return: new Path
        """
        return Path(self.size, [p.update(z=z) for p in self.points])

    cpdef Path copy(self):
        return Path(self.size, copy(self.points))

    def __copy__(self):
        return self.copy()

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
        self.points = points or []
        self.size = size

    @property
    def head(self) -> Vector:
        try:
            return self.points[-1]
        except IndexError:
            raise NotReadyError('Path must contain at least one element')

    cpdef void set_size(self, Vector value):
        self.size = value

    cpdef Path simplify(self):
        """
        Return this path, but with points that are colinear to adjacent points removed
        """
        cdef Line line
        cdef list indices_to_remove = []
        for prev, mid, next_vector, index in zip(self.points, self.points[1:], self.points[2:], count(self.points, start_at=1)):
            line = Line(prev, next_vector)
            if line.is_colinear(mid):
                indices_to_remove.add(index)
        cdef list points = [point for i, point in enumerate(self.points) if i not in indices_to_remove]
        return Path(self.size, points)

    cpdef int advance(self, delta: Vector) except -1:
        """Place next segment of the path at given difference from current head"""
        self.head  # raises NotReadyError

        if iszero(delta.length):
            return 0

        self.points.append(self.head.add(delta))
        return 0

    cpdef int elevate(self, height: float, delta: float) except -1:
        """
        Change elevation (z-value) to given
        
        :param height: target elevation 
        :param delta: step size to take
        """
        self.head_towards(self.head.update(z=height), delta)

    cpdef int head_towards(self, point: Vector, delta: float) except -1:
        """
        Place next pieces of the path at delta distances going towards the point. The last
        segment may be shorter

        :param point: point to advance towards
        :param delta: size of step to use in constructing the path
        """
        if iszero((point.sub(self.head)).length):
            return 0

        while point != self.head:
            vector_towards = point.sub(self.head)
            if vector_towards.length < delta:
                return self.advance(vector_towards)
            self.advance(vector_towards.unitize().mul(delta))

        return 0

    def __getitem__(self, item: int) -> Vector:
        return self.points[item]

    def __len__(self) -> int:
        return len(self.points)

    def __iter__(self) -> tp.Iterator[tp.Box]:
        for point in self.points:
            yield Box.centered_with_size(point, self.size)

    cpdef int append(self, object elem) except -1:  # type: (tp.Union[Vector, Box]) -> None
        cdef Box box
        cdef Vector center, vector
        if isinstance(elem, Box):
            box = elem
            if self.size is None:
                self.size = box.size
                center = box.center
                self.points.append(center)
            else:
                if elem.size != self._size:
                    warnings.warn('Size of next path element differs from the base element. '
                                  'It will be disregarded.', ValueWarning)
                self.points.append(self.head)
        else:
            vector = elem
            if self._size is None:
                raise ValueError('Path must have at least one Box element!')
            self.points.append(vector)

    def __contains__(self, item: Box) -> bool:
        """Return if the box item intersects with this path"""
        for box in self:
            if item.collides(box):
                return True
        return False

    def get_intersecting_boxes(self, other: Path) -> tp.Iterator[Box]:
        """
        Return all intersections of these elements that collide.
        """
        cdef Path path = other
        cdef Box elem1, elem2

        for elem1, elem2 in half_product(self, path):
            if elem1.collides(elem2):
                yield elem1, elem2

    cpdef double get_length(self):
        """Calculate and return the total length of this path"""
        cdef double length = 0
        cdef Vector prev_p, next_p
        for prev_p, next_p in add_next(self.points):
            if next_p is None:
                return length
            length += prev_p.distance_to(next_p)
