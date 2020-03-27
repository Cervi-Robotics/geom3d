#!/bin/bash

set -x
set -e

function build_and_test() {
  pip install coverage
  pip install -r requirements.txt
  curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 > ./cc-test-reporter
  chmod +x ./cc-test-reporter
  ./cc-test-reporter before-build
  python setup.py test
  coverage xml
  ./cc-test-reporter after-build -t coverage.py --exit-code $TRAVIS_TEST_RESULT
}

if [ $TRAVIS_BRANCH == "master" ]; then
    if [ $BUILD == "true" ]; then
      docker pull $DOCKER_IMAGE
      docker run --rm -e PLAT=$PLAT -v `pwd`:/io $DOCKER_IMAGE $PRE_CMD /io/travis/build-wheels.sh
      cd wheelhouse
      twine upload -u "$PYPI_USER" -p "$PYPI_PWD" *
    else
      build_and_test()
    fi
else
  build_and_test()
fi
