UPX_ARGS ?= -6
TAG      ?= $(shell git rev-parse HEAD)
IMAGE    ?= quay.io/steigr/lostromos

image:
	docker build --build-arg="UPX_ARGS=$(UPX_ARGS)" --tag="$(IMAGE):$(TAG)" .

push: image
	docker push "$(IMAGE):$(TAG)"

release:
	UPX_ARGS="-9 --best --brute --ultra-brute" TAG="$(shell git describe --tags)" make image push
	UPX_ARGS="-9 --best --brute --ultra-brute" TAG="latest" make image push