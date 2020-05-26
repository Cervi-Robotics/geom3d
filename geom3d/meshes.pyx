import typing as tp

from libc.math cimport sqrt

from .base cimport iszero, isclose
from .basic cimport Vector, Line


cdef class Ray:
    """
    A ray that has an origin point and a direction vector
    """
    def __init__(self, start: Vector, unit_vector: Vector):
        self.start = start
        self.unit_vector = unit_vector
        assert isclose(unit_vector.length, 1), 'Unit vector has to be of length 1'

    cpdef bint collides(self, Triangle triangle):
        cdef:
            Vector u, v, n, w0, w
            double r, a, b, uu, uv, vv, wu, wv, d, s, t
            bint result

        u = triangle.b.sub(triangle.a)
        v = triangle.c.sub(triangle.b)
        n = u.cross_product(v)

        if n.is_zero():
            return False

        w0 = self.start.sub(triangle.a)
        a = n.neg().dot_product(w0)
        b = n.dot_product(self.unit_vector)

        if iszero(b):
            return iszero(a)

        r = a / b
        if r < 0:
            return False

        p = self.start.add(self.unit_vector.mul(r))
        uu = u.dot_square()
        uv = u.dot_product(v)
        vv = v.dot_square()
        w = p.sub(triangle.a)
        wu = w.dot_product(u)
        wv = w.dot_product(v)
        d = uv * uv - uu * vv
        s = (uv * wv - vv * wu) / d

        if s < 0 or s > 1:
            return False

        t = (uv*wu - uu*wv) / d

        if t < 0 and (s+t) > 1:
            return False
        return True

cdef class Triangle:
    """
    A triangle defined by it's 3 vertices
    """
    def __init__(self, a: Vector, b: Vector, c: Vector):
        self.a = a
        self.b = b
        self.c = c

    cpdef double get_perimeter_length(self):
        """Return the length of triangle's perimeter"""
        cdef double a
        cdef double b
        cdef double c
        a, b, c = self.get_edges_length()
        return a + b + c

    cpdef tuple get_edges(self):  # type: () -> tp.Tuple[Line, Line, Line]
        """Return edges of this triangle"""
        return Line(self.a, self.b), Line(self.b, self.c), Line(self.c, self.a)

    cpdef tuple get_edges_length(self):  # type: () -> tp.Tuple[float, float, float]
        """Return lengths of edges corresponding to n-th edge"""
        return self.a.distance_to(self.b), self.b.distance_to(self.c), \
               self.c.distance_to(self.b)

    cpdef double get_surface_area(self):
        """Return the surface area of this triangle"""
        cdef double s = self.get_perimeter_length()
        cdef double a, b, c
        a, b, c = self.get_edges_length()
        return sqrt(s * (s - a) * (s - b) * (s - c))
