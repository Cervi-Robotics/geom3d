set -x
set -e

pip install --upgrade pip
pip install coverage nose2
pip install -r requirements.txt
curl -L https://codeclimate.com/downloads/test-reporter/test-reporter-latest-linux-amd64 > ./cc-test-reporter
chmod +x ./cc-test-reporter
./cc-test-reporter before-build
coverage run -m nose2 -vvv
TRAVIS_TEST_RESULT=$?
coverage xml
./cc-test-reporter after-build -t coverage.py --exit-code ${TRAVIS_TEST_RESULT}
exit $TRAVIS_TEST_RESULT

