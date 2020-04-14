import cython

# Please redefine epsilon if you find it too little
# This is used for math.isclose(abs_tol=) calculations too

cdef double EPSILON = 0.01

@cython.cdivision(False)
cdef double true_modulo(double a, double b):
    # we care about getting Python's modulo here
    return a % b

cpdef void set_epsilon(double new_epsilon):
    """
    Set a new value of epsilon.

    Epsilon is used to compare two floats, and to determine the handness of the vector
    inside/outside the polygon

    :param new_epsilon: new value of epsilon
    """
    global EPSILON
    EPSILON = new_epsilon
