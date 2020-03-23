FROM python:3.7

RUN pip install wheel twine

ADD requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

ADD . /app/
WORKDIR /app
RUN python setup.py bdist_wheel

CMD ["twine", "upload", "dist/*"]
