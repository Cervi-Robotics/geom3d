#!/bin/bash

set -x
set -e

if [ "$1" == "travis" ]; then
  docker pull "$DOCKER_IMAGE"
  docker run --rm -it -e PLAT=$PLAT -e PYPI_USER="$PYPI_USER" -e PYPI_PWD="$PYPI_PWD" -v `pwd`:/io $DOCKER_IMAGE bash /io/tests/build.sh
else

  yum install -y atlas-devel
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

  /opt/python/cp38-cp38/bin/pip install twine
  /opt/python/cp38-cp38/bin/twine upload -u "$PYPI_USER" -p "$PYPI_PWD" wheelhouse/*
fi
