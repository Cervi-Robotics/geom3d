from setuptools import setup
from snakehouse import Multibuild, build
from setuptools import Extension

import os

ext_modules = build([
      Extension('geom3d.base', ['geom3d/base.pyx']),
      Extension('geom3d.basic', ['geom3d/basic.pyx']),
      Multibuild('geom3d.degrees', [os.path.join('geom3d', 'degrees', 'planets.pyx'),
                                    os.path.join('geom3d', 'degrees', 'coordinates.pyx')]),
      Extension('geom3d.paths.nonintersecting', ['geom3d/paths/nonintersecting.pyx']),
      Extension('geom3d.polygons.twodimensional', ['geom3d/polygons/twodimensional.pyx']),
      Extension('geom3d.paths.polygon', ['geom3d/paths/polygon.pyx']),
], compiler_directives={
      'language_level': '3'
})

setup(keywords=['geometry', '3d', 'flight', 'path'],
      packages=['geom3d', 'geom3d.degrees', 'geom3d.meshes', 'geom3d.paths', 'geom3d.polygons'],
      version='0.4_a3',
      install_requires=[
            'satella',
      ],
      tests_require=[
          "nose2", "mock", "coverage", "nose2[coverage_plugin]"
      ],
      test_suite='nose2.collector.collector',
      python_requires='!=2.7.*,!=3.0.*,!=3.1.*,!=3.2.*,!=3.3.*,!=3.4.*',
      ext_modules=ext_modules
      )

