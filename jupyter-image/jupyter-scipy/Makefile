TAG ?= $(shell git describe --tags --always --dirty)

docker-build:
	docker build -t jupyter-scipy:${TAG} -f Dockerfile . 

docker-push:
	docker push jupyter-scipy:${TAG}