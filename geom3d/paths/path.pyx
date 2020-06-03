import itertools
import typing as tp
import logging
import warnings
from copy import copy
from satella.coding.sequences import add_next, count

from ..base cimport iszero, isclose
from ..basic cimport Box, Vector, Line
from ..exceptions import ValueWarning, NotReadyError

logger = logging.getLogger(__name__)


cdef class Path:
    def __init__(self, size: tp.Optional[Vector] = None,
                 points: tp.Optional[tp.List[Vector]] = None):
        self.points = points or []
        self.size = size

    def __add__(self, other: Path):
        return Path(self.size, self.points + other.points)

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
        cdef:
            Line line
            list indices_to_remove = []
            set indices_to_remove_set
            list points
        for prev, mid, next_vector, index in zip(self.points, self.points[1:], self.points[2:], count(self.points, 1)):
            line = Line(prev, next_vector)
            if line.is_colinear(mid):
                indices_to_remove.append(index)
        indices_to_remove_set = set(indices_to_remove)
        points = [point for i, point in enumerate(self.points) if i not in indices_to_remove_set]
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
        cdef:
            double len_current = 0
            double len_between
            Vector prev_point, next_point
            Line line

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
        cdef:
            double len_current = 0
            Vector prev_point = self.points[0]
            Vector next_point
            int i  # index to insert before
            double dist_length

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

    cdef Box get_box_at(self, int i):
        return Box.centered_with_size(self.points[i], self.size)

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
        cdef:
            Box box
            Vector center, vector

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
        cdef:
            Path path = other
            Box elem1, elem2

        for elem1, elem2 in itertools.product(self, other):
            if elem1.collides(elem2):
                yield elem1

    cpdef bint does_collide(self, Path other):
        cdef Box elem1, elem2
        for elem1, elem2 in itertools.product(self, other):
            if elem1.collides(elem2):
                return True
        return False

    cpdef list get_intersecting_boxes_indices(self, Path other):
        """
        Return all indices of boxes that intersect with any other box in other's path
        """
        cdef:
            Path path = other
            Box elem1, elem2
            tuple row
            int i
            set indices = set()

        for row, elem2 in itertools.product(enumerate(self), other):
            i, elem1 = row
            if elem1.collides(elem2):
                indices.add(i)
        return list(indices)

    cpdef double get_length(self):
        """Calculate and return the total length of this path"""
        cdef:
            double length = 0
            Vector prev_p, next_p

        for prev_p, next_p in add_next(self.points):
            if next_p is None:
                return length
            length += prev_p.distance_to(next_p)

    cpdef double avg_z(self):
        """Return arithmetic mean of all z-values of constituent points"""
        cdef:
            double sum_e
            int count
            Vector vector

        for vector in self.points:
            sum_e += vector.z
            count += 1
        return sum_e / count

    def as_segments(self) -> tp.Iterator[Line]:
        """
        Convert this path to a bunch of segments
        """
        cdef:
            Vector p1, p2

        for p1, p2 in add_next(self.points, skip_last=True):
            yield Line(p1, p2)

    cpdef void set_z(self, double new_z):
        """
        Set all Z positions in this path to a provided one
        """
        self.points = [point.set_z(new_z) for point in self.points]

    cdef bint eq(self, Path other):
        return self.size.eq(other.size) and self.points == other.points

    def __eq__(self, other: Path):
        return self.eq(other)


cpdef void get_mutual_intersecting(Path path1, Path path2, set to_path1, set to_path2):
    """
    Get indices of mutually intersecting boxes in two paths.
    
    :param path1: first path to analyze
    :param path2: second path to analyze
    :param to_path1: set in which indices of boxes in path1 that collide will be placed
    :param to_path2: set in which indices of boxes in path2 that collide will be placed
    """
    cdef:
        Box box1, box2
        int i, j

    for i, box1 in enumerate(path1):
        for j, box2 in enumerate(path2):
            if box1.collides(box2):
                to_path1.add(i)
                to_path2.add(j)

cpdef void get_still_mutual_intersecting(Path path1, Path path2, set to_path1, set to_path2, list ind_path1, list ind_path2):
    """
    Analyze a subset of points previously proved to be collisible.
    
    :param path1: first path to analyze
    :param path2: second path to analyze
    :param to_path1: set in which indices of boxes in path1 that collide will be placed
    :param to_path2: set in which indices of boxes in path2 that collide will be placed
    :param ind_path1: indices of boxes in path1 to check
    :param ind_path2: indices of boxes in path1 to check
    """
    cdef:
        Box box1, box2
        int i, j

    for i in ind_path1:
        for j in ind_path2:
            if path1.get_box_at(i).collides(path2.get_box_at(j)):
                to_path1.add(i)
                to_path2.add(j)

