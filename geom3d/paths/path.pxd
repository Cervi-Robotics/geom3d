from ..basic cimport Vector


cdef class Path:
    cdef:
        public Vector size
        public list points

    cpdef set_size(self, Vector value)

