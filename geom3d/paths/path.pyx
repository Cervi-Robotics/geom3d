import itertools
import typing as tp
import logging
import warnings
from copy import copy
from satella.coding.sequences import half_product, add_next, count

from ..base cimport iszero, isclose
from ..basic cimport Box, Vector, Line
from ..exceptions import ValueWarning, NotReadyError

logger = logging.getLogger(__name__)


cdef class Path:
    def __init__(self, size: tp.Optional[Vector] = None,
                 points: tp.Optional[tp.List[Vector]] = None):
        self.points = points or []
        self.size = size

    cpdef Path reverse(self):
        """Return this path, but backwards"""
        return Path(self.size, self.points[::-1])

    cpdef Path translate_z(self, double delta):
        """
        Return this path, but with every point added delta
        
        :param delta: parameter to add to z axis 
        """
        cdef list points = [point.add(Vector(0, 0, delta)) for point in self.points]
        return Path(self.size, points)

    cpdef Path set_z(self, double z):
        """
        Change the z of every vector to that provided.

        :param z: new z to set for every vector

        :return: new Path
        """
        return Path(self.size, [p.set_z(z) for p in self.points])

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
        for prev, mid, next_vector, index in zip(self.points, self.points[1:], self.points[2:], count(self.points, 1)):
            line = Line(prev, next_vector)
            if line.is_colinear(mid):
                indices_to_remove.append(index)
        cdef set indices_to_remove_set = set(indices_to_remove)
        cdef list points = [point for i, point in enumerate(self.points) if i not in indices_to_remove_set]
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

    cpdef Vector get_vector_at(self, double length):
        """
        Get a vector that would appear at length from the start.
        
        If the length given is longer than the path, the vector will be extrapolated
        from two last points and an UserWarning will be given
        """
        cdef double len_current = 0
        cdef double len_between
        cdef Vector prev_point, next_point
        cdef Line line

        for prev_point, next_point in add_next(self.points, skip_last=True):
            len_between = prev_point.distance_to(next_point)
            if iszero(length):
                return prev_point
            if isclose(len_between, length):
                return next_point
            elif len_between > length:
                return Line(prev_point, next_point).get_point(length).to_vector()
            length -= len_between
        else:
            warnings.warn('Length greater than the path, extrapolating', UserWarning)
            len_between = self.points[-2].distance_to(self.points[-1])
            length += len_between
            return Line(self.points[-2], self.points[-1]).get_point(length).to_vector()

    cpdef void insert_at(self, Vector vector, double length):
        """
        Insert given vector at some distance from the path's start
        
        :param vector: vector to insert 
        :param length: length from the start
        """
        cdef double len_current = 0
        cdef Vector prev_point = self.points[0]
        cdef Vector next_point
        cdef int i  # index to insert before
        cdef double dist_length
        if iszero(length):
            self.points[0] = vector
            return
        for i, next_point in enumerate(self.points[1:], start=1):
            len_current += prev_point.distance_to(next_point)
            if isclose(len_current, length):
                self.points[i] = vector
                return
            if len_current > length:
                self.points.insert(i, vector)
                return
            prev_point = next_point
        else:
            self.points.append(vector)

    def __getitem__(self, item):
        return self.points[item]

    def __setitem__(self, key: int, value: Vector):
        self.points[key] = value

    def __delitem__(self, key):
        del self.points[key]

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
        Return all boxes that intersect with any other box in other's path
        """
        cdef Path path = other
        cdef Box elem1, elem2

        for elem1 in self:
            for elem2 in path:
                if elem1.collides(elem2):
                    yield elem1

    cpdef bint does_collide(self, Path other):
        cdef Box elem1, elem2
        for elem1 in self:
            for elem2 in other:
                if elem1.collides(elem2):
                    return True
        return False

    cpdef list get_intersecting_boxes_indices(self, Path other):
        """
        Return all indices of boxes that intersect with any other box in other's path
        """
        cdef Path path = other
        cdef Box elem1, elem2
        cdef int i
        cdef list indices = []
        for row, elem1 in enumerate(self):
            for elem2 in path:
                i, elem1 = row
                if elem1.collides(elem2):
                    indices.append(i)
        return indices

    cpdef double get_length(self):
        """Calculate and return the total length of this path"""
        cdef double length = 0
        cdef Vector prev_p, next_p
        for prev_p, next_p in add_next(self.points):
            if next_p is None:
                return length
            length += prev_p.distance_to(next_p)

    cpdef double avg_z(self):
        """Return arithmetic mean of all z-values of constituent points"""
        cdef double sum_e
        cdef int count
        cdef Vector vector
        for vector in self.points:
            sum_e += vector.z
            count += 1
        return sum_e / count

    cpdef Path2D to_path2D(self):
        """
        Return this path as a Path2D
        """
        return Path2D(self.size, self.points)


cdef class Path2D(Path):
    """
    Path in which only x, y coordinates ever matter
    """
    def __init__(self, size: tp.Optional[Vector] = None,
                 points: tp.Optional[tp.List[Vector]] = None):
        super().__init__(size, points or [])

    cpdef list get_intersecting_boxes_indices(self, Path other):
        """
        Return all indices of boxes that intersect with any other box in other's path
        """
        cdef Box elem1, elem2
        cdef int i
        cdef list indices = []
        cdef Path2D other2
        if isinstance(other, Path2D):
            other2 = other
            for i, elem1 in enumerate(self):
                for elem2 in other2:
                    if elem1.collides_xy(elem2):
                        indices.append(i)
            return indices
        else:
            return super().get_intersecting_boxes_indices(other)

    cpdef bint does_collide(self, Path other):
        cdef Path2D other2
        cdef Box elem1, elem2
        if isinstance(other, Path2D):
            other2 = other
            for elem1 in self:
                for elem2 in other2:
                    if elem1.collides_xy(elem2):
                        return True
            return False
        else:
            return super().does_collide(other)

    def get_intersecting_boxes(self, other: Path) -> tp.Iterator[Box]:
        """
        Return all boxes that intersect with any other box in other's path
        """
        cdef Box elem1, elem2
        cdef Path2D other2
        if isinstance(other, Path2D):
            other2 = other
            for elem1 in self:
                for elem2 in other2:
                    if elem1.collides_xy(elem2):
                        yield elem1
        else:
            return super().get_intersecting_boxes(other)

    cpdef Path2D set_z(self, double z):
        return Path2D(self.size, [point.set_z(z) for point in self.points])

    cpdef Path2D copy(self):
        return Path2D(self.size, self.points.copy())

    cpdef Path2D simplify(self):
        cdef Line line
        cdef int index
        cdef list indices_to_remove = []
        for prev, mid, next_vector, index in zip(self.points, self.points[1:], self.points[2:], count(self.points, 1)):
            prev = prev.set_z(0)
            next_vector = next_vector.set_z(0)
            mid = mid.set_z(0)
            line = Line(prev, next_vector)
            if line.is_colinear(mid):
                indices_to_remove.append(index)
        cdef set indices_to_remove_set = set(indices_to_remove)
        cdef list points = [point for i, point in enumerate(self.points) if i not in indices_to_remove_set]
        return Path2D(self.size, points)

    cpdef Path2D reverse(self):
        return Path2D(self.size, self.points[::-1])

    cpdef Path to_path(self):
        return Path(self.size, self.points.copy())
