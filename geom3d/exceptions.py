from satella.exceptions import CustomException

__all__ = ['GeomError', 'GeomWarning', 'ValueWarning']


class GeomError(CustomException):
    """Base class for all Geom errors"""


class GeomWarning(Warning):
    """Base class for all Geom warnings"""


class ValueWarning(GeomWarning):
    """Warning about some value of your argument"""
