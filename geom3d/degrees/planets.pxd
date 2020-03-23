cdef class Planet:
    cdef:
        public double radius_at_equator
        public double circumference_at_pole

cdef class Earth(Planet):
    pass
