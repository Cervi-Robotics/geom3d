FROM python:3.8

ADD requirements.txt /tmp/requirements.txt
RUN pip install --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org -r /tmp/requirements.txt
RUN pip install --trusted-host pypi.python.org --trusted-host files.pythonhosted.org --trusted-host pypi.org nose2 mock coverage nose2[coverage_plugin]

ADD . /app/
WORKDIR /app

CMD ["python", "setup.py", "test"]
