from libc.math cimport M_PI, cos


cdef class Planet:
    """
    A generic geoid. This is assumes to have to different circumferences - one going through the
    equator, and the second one going through the pole.
    """
    cpdef double get_circumference_at_latitude(self, double latitude):
        """
        Calculate circumference going through given latitude
        
        :param latitude: latitude, in degrees
        """
        return 2 * M_PI * self.radius_at_equator * cos(to_radians(latitude))


cdef class Earth(Planet):
    def __init__(self):
        self.radius_at_equator = 6378000.0
        self.circumference_at_pole = 40008000.0


cdef class CustomPlanet(Planet):
    def __init__(self, radius_at_equator: float, circumference_at_pole: float):
        self.radius_at_equator = radius_at_equator
        self.circumference_at_pole = circumference_at_pole
