from setuptools import setup, find_packages
from snakehouse import Multibuild, build
from setuptools import Extension

ext_modules = build([
      Extension('geom3d.base', ['geom3d/base.pyx']),
      Extension('geom3d.basic', ['geom3d/basic.pyx']),
      Extension('geom3d.polygons.twodimensional', ['geom3d/polygons/twodimensional.pyx']),
      Extension('geom3d.paths.polygon', ['geom3d/paths/polygon.pyx']),
], compiler_directives={
      'language_level': '3'
})

setup(keywords=['geometry', '3d', 'flight', 'path'],
      packages=find_packages(include=['geom3d', 'geom3d.*']),
      version='0.3_a1',
      install_requires=[
            'satella', 'Cython'
      ],
      tests_require=[
          "nose2", "mock", "coverage", "nose2[coverage_plugin]"
      ],
      test_suite='nose2.collector.collector',
      python_requires='!=2.7.*,!=3.0.*,!=3.1.*,!=3.2.*,!=3.3.*,!=3.4.*',
      ext_modules=ext_modules
      )

