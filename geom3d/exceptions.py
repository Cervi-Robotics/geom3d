from satella.exceptions import CustomException

__all__ = ['GeomError', 'GeomWarning', 'ValueWarning']


class GeomError(CustomException):
    """Base class for all Geom errors"""


class GeomWarning(Warning):
    """Base class for all Geom warnings"""


class ValueWarning(GeomWarning):
    """Warning about some value of your argument"""


class NotReadyError(GeomError):
    """Something needs to be done before the object can accept this request"""