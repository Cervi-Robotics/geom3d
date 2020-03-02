__all__ = ['GeomError']


class GeomError(Exception):
    """"Base class for all Geom exceptions"""
    def __init__(self, msg, *args, **kwargs):
        super().__init__(*(msg, *args))
        self.kwargs = kwargs
        self.msg = msg

    def __str__(self):
        a = '%s(%s' % (self.__class__.__qualname__, self.args)
        if self.kwargs:
            a += ', '+(', '.join(map(lambda k, v: '%s=%s' % (k, repr(v)), self.kwargs.items())))
        a += ')'
        return a

    def __repr__(self):
        a = '%s%s(%s' % ((self.__class__.__module__ + '.')
                         if self.__class__.__module__ != 'builtins' else '',
                         self.__class__.__qualname__,
                         ', '.join(map(repr, self.args)))
        if self.kwargs:
            a += ', ' + (', '.join(map(lambda kv: '%s=%s' % (kv[0], repr(kv[1])),
                                       self.kwargs.items())))
            a += ')'
        return a

