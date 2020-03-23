cdef class Planet:
    ...


cdef class Earth(Planet):
    def __init__(self):
        self.radius_at_equator = 6378000
        self.circumference_at_pole = 40008000
