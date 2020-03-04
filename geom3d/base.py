
# Please redefine epsilon if you find it too little
# This is used for math.isclose(abs_tol=) calculations too
import math

EPSILON = 0.01

# Use it only like
# >>> from . import base
# >>> base.EPSILON


def isclose(a: float, b: float) -> bool:
    """
    Are the two numbers equal according to local epsilon?
    """
    return math.isclose(a, b, abs_tol=EPSILON)


def iszero(a: float) -> bool:
    """
    Is a zero according to local epsilon?
    """
    return isclose(a, 0)


def set_epsilon(new_epsilon: float):
    """
    Set a new value of epsilon.

    Epsilon is used to compare two floats, and to determine the handness of the vector
    inside/outside the polygon

    :param new_epsilon: new value of epsilon
    """
    global EPSILON
    EPSILON = new_epsilon
