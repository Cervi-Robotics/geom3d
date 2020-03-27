#!/bin/bash

set -x
set -e

pip install twine
docker pull $DOCKER_IMAGE
docker run --rm -e PLAT=$PLAT -v `pwd`:/io $DOCKER_IMAGE $PRE_CMD /io/travis/build-wheels.sh
cd wheelhouse
twine upload -u "$PYPI_USER" -p "$PYPI_PWD" *

