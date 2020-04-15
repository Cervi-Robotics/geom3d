from setuptools import setup
from snakehouse import Multibuild, build
from setuptools import Extension
from satella.files import find_files


ext_modules = build([
      Extension('geom3d.base', ['geom3d/base.pyx']),
      Extension('geom3d.basic', ['geom3d/basic.pyx']),
      Multibuild('geom3d.polygons', find_files('geom3d/polygons', r'(.*)\.pyx')),
      Multibuild('geom3d.meshes', find_files('geom3d/meshes', r'(.*)\.pyx')),
      Multibuild('geom3d.paths', find_files('geom3d/paths', r'(.*)\.pyx')),
      Multibuild('geom3d.degrees', find_files('geom3d/degrees', r'(.*)\.pyx')),
], compiler_directives={
      'language_level': '3',
      'linetrace': True
})

setup(keywords=['geometry', '3d', 'flight', 'path'],
      packages=['geom3d', 'geom3d.degrees', 'geom3d.meshes', 'geom3d.paths', 'geom3d.polygons'],
      version='0.5_a1',
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

