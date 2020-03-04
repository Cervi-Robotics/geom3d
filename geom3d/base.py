
# Please redefine epsilon if you find it too little
# This is used for math.isclose(abs_tol=) calculations too
EPSILON = 0.01

# Use it only like
# >>> from . import base
# >>> base.EPSILON


def set_epsilon(new_epsilon: float):
    """Set a new value of epsilon"""
    global EPSILON
    EPSILON = new_epsilon
