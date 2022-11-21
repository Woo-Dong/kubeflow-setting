TAG ?= $(shell git describe --tags --always --dirty)
ACCOUNT_ID ?= $(shell git describe --account-id --always --dirty)
REGISTRY ?= ${ACCOUNT_ID}.dkr.ecr.ap-northeast-2.amazonaws.com

docker-build-all:
	@echo "\nBuilding jupyter-scipy image...\n"
	make docker-build -C jupyter-scipy TAG=${TAG} 

	@echo "\nBuilding jupyter-tensorflow image...\n"
	make docker-build-cpu -C jupyter-tensorflow TAG=${TAG} 

	@echo "\nBuilding jupyter-tensorflow-cuda image...\n"
	make docker-build-cuda -C jupyter-tensorflow TAG=${TAG} 

	@echo "\nAll notebook-server images have been successfully built...\n"

docker-push-all:
	for img in jupyter-scipy \
		jupyter-tensorflow \
		jupyter-tensorflow-cuda; do \
		docker tag $$img:${TAG} ${REGISTRY}/$$img:${TAG} ; \
		docker push ${REGISTRY}/$$img:${TAG} ; \
	done
