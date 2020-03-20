from abc import ABCMeta, abstractmethod


class Planet(metaclass=ABCMeta):
    @property
    @abstractmethod
    def radius_at_equator(self) -> float:
        """expressed in metres"""

    @property
    @abstractmethod
    def circumference_at_pole(self) -> float:
        """expressed in metres"""


class Earth(Planet):
    radius_at_equator = 6378000
    circumference_at_pole = 40008000
