__version__ = '0.1a3'

from .basic import Line, PointInLine, Vector, Box
from .paths import Path
from .base import set_epsilon

__all__ = ['Line', 'PointInLine', 'Vector', 'Box', 'Path', 'set_epsilon']
