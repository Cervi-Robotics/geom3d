from setuptools import setup, find_packages

from geom3d import __version__

setup(keywords=['geometry', '3d', 'flight', 'path'],
      packages=find_packages(include=['geom3d', 'geom3d.*']),
      version=__version__,
      install_requires=[
            'satella', 'pint', 'LatLon'
      ],
      tests_require=[
          "nose2", "mock", "coverage", "nose2[coverage_plugin]"
      ],
      test_suite='nose2.collector.collector',
      python_requires='!=2.7.*,!=3.0.*,!=3.1.*,!=3.2.*,!=3.3.*,!=3.4.*',
      )
