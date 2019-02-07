SHELL = /bin/sh
.SUFFIXES:
.PHONY: help
.DEFAULT_GOAL := help

# Docker parameters
ROOT_FOLDER=$(shell pwd)
NS ?= pfillion
VERSION ?= latest
IMAGE_NAME ?= drone-dind
CONTAINER_NAME ?= drone-dind
CONTAINER_INSTANCE ?= default
VCS_REF=$(shell git rev-parse --short HEAD)
BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%S")

help: ## Show the Makefile help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the image form Dockerfile
	docker build \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg VCS_REF=$(VCS_REF) \
		--build-arg VERSION=$(VERSION) \
		-t $(NS)/$(IMAGE_NAME):$(VERSION) -f Dockerfile .

push: ## Push the image to a registry
ifdef DOCKER_USERNAME
	echo "$(DOCKER_PASSWORD)" | docker login -u "$(DOCKER_USERNAME)" --password-stdin
endif
	docker push $(NS)/$(IMAGE_NAME):$(VERSION)
    
shell: start ## Run shell command in the container
	docker exec -it $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) /bin/sh
	$(docker_stop)

start: ## Run the container in background
	docker run -d --rm --privileged --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(VERSION)

stop: ## Stop the container
	$(docker_stop)

test: ## Run all tests
	docker run \
		--rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(ROOT_FOLDER)/tests:/tests \
		gcr.io/gcp-runtimes/container-structure-test:latest \
			test \
			--image $(NS)/$(IMAGE_NAME):$(VERSION) \
			--config /tests/config.yaml

release: build push ## Build and push the image to a registry

define docker_stop
	docker stop $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)
endef