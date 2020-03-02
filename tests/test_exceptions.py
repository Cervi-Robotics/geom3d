import unittest

from geom3d.exceptions import GeomError


class TestExceptions(unittest.TestCase):

    def test_exception_kwargs(self):
        e = GeomError('hello world', label='value')
        self.assertIn("label='value'", repr(e))

    def test_exception(self):
        try:
            raise GeomError('message', 'arg1', 'arg2')
        except GeomError as e:
            self.assertIn('arg1', str(e))
            self.assertIn('arg2', str(e))
            self.assertIn('GeomError', str(e))
        else:
            self.fail()

    def test_except_inherited(self):
        class InheritedException(GeomError):
            pass

        try:
            raise InheritedException('message', 'arg1', 'arg2')
        except GeomError as e:
            self.assertIn('arg1', str(e))
            self.assertIn('arg2', str(e))
            self.assertIn('InheritedException', str(e))
        else:
            self.fail()
