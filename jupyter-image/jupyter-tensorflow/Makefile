TAG ?= $(shell git describe --tags --always --dirty)

docker-build-cpu:
	docker build -t jupyter-tensorflow:${TAG} -f cpu.Dockerfile . 

docker-build-cuda:
	docker build -t jupyter-tensorflow-cuda:${TAG} -f cuda.Dockerfile . 

docker-push-cpu: 
	docker push jupyter-tensorflow:${TAG}

docker-push-cuda:
	docker push jupyter-tensorflow-cuda:${TAG}