cpdef double avg(list floats):
    cdef:
        double sum_ = 0
        int count = 0
        double flt

    for flt in floats:
        sum_ += flt
        count += 1

    return sum_/count
