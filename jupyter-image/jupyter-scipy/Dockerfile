# Use the respective Makefile to pass the appropriate BASE_IMG and build the image correctly
FROM kubeflownotebookswg/jupyter:v1.6.0-rc.0

# install - requirements.txt
COPY --chown=jovyan:users requirements.txt /tmp/requirements.txt

RUN python3 -m pip install --upgrade pip

RUN python3 -m pip install -r /tmp/requirements.txt --quiet --no-cache-dir \
    && rm -f /tmp/requirements.txt
