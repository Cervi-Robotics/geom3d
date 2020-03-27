#!/bin/bash

set -x
set -e

if [ "$1" == "travis" ]; then
  docker run --rm -it -e PLAT=$PLAT -v `pwd`:/io "$DOCKER_IMAGE" bash /io/tests/build.sh

  pip install twine
  twine upload -u "$PYPI_USER" -p "$PYPI_PWD" wheelhouse/geom3d-*manylinux*.whl
else
  # Executed in target dockerized CentOS 5 environment
  rm -rf /opt/python/cp27-cp27m
  rm -rf /opt/python/cp27-cp27mu
  rm -rf /opt/python/cp34-cp34m
  rm -rf /opt/python/cp34-cp34mu

  cd /io

  # Compile wheels
  for PYBIN in /opt/python/*/bin; do
      "${PYBIN}/pip" install -r /io/requirements.txt
      "${PYBIN}/pip" wheel /io/ -w wheelhouse/
  done

  # Bundle external shared libraries into the wheels
  for whl in wheelhouse/*.whl; do
      auditwheel repair "$whl" --plat $PLAT -w /io/wheelhouse/
  done
fi
