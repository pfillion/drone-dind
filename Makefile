SHELL = /bin/sh
.SUFFIXES:
.PHONY: help
.DEFAULT_GOAL := help

# Tools Version
BATS_VERSION		:= 1.12.0
CST_VERSION			:= 1.19.3

# Docker-dind Version
VERSION            := 28.2.2
VERSION_PARTS      := $(subst ., ,$(VERSION))

MAJOR              := $(word 1,$(VERSION_PARTS))
MINOR              := $(word 2,$(VERSION_PARTS))
MICRO              := $(word 3,$(VERSION_PARTS))

CURRENT_VERSION_MICRO := $(MAJOR).$(MINOR).$(MICRO)
CURRENT_VERSION_MINOR := $(MAJOR).$(MINOR)
CURRENT_VERSION_MAJOR := $(MAJOR)

DATE                = $(shell date -u +"%Y-%m-%dT%H:%M:%S")
COMMIT             := $(shell git rev-parse HEAD)
AUTHOR             := $(firstword $(subst @, ,$(shell git show --format="%aE" $(COMMIT))))

# Docker parameters
ROOT_FOLDER=$(shell pwd)
NS ?= pfillion
IMAGE_NAME ?= drone-dind
CONTAINER_NAME ?= drone-dind
CONTAINER_INSTANCE ?= default

help: ## Show the Makefile help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

version: ## Show all versionning infos
	@echo BATS_VERSION="$(BATS_VERSION)"
	@echo CST_VERSION="$(CST_VERSION)"
	@echo CURRENT_VERSION_MICRO="$(CURRENT_VERSION_MICRO)"
	@echo CURRENT_VERSION_MINOR="$(CURRENT_VERSION_MINOR)"
	@echo CURRENT_VERSION_MAJOR="$(CURRENT_VERSION_MAJOR)"
	@echo DATE="$(DATE)"
	@echo COMMIT="$(COMMIT)"
	@echo AUTHOR="$(AUTHOR)"

build: ## Build the image form Dockerfile
	docker build \
		--build-arg BATS_VERSION=$(BATS_VERSION) \
		--build-arg CST_VERSION=$(CST_VERSION) \
		--build-arg DATE=$(DATE) \
		--build-arg CURRENT_VERSION_MICRO=$(CURRENT_VERSION_MICRO) \
		--build-arg COMMIT=$(COMMIT) \
		--build-arg AUTHOR=$(AUTHOR) \
		-t $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MICRO) \
		-t $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MINOR) \
		-t $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MAJOR) \
		-t $(NS)/$(IMAGE_NAME):latest \
		-f Dockerfile .

push: ## Push the image to a registry
ifdef DOCKER_USERNAME
	echo "$(DOCKER_PASSWORD)" | docker login -u "$(DOCKER_USERNAME)" --password-stdin
endif
	docker push $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MICRO)
	docker push $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MINOR)
	docker push $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MAJOR)
	docker push $(NS)/$(IMAGE_NAME):latest
    
shell: start ## Run shell command in the container
	docker exec -it $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) /bin/sh
	$(docker_stop)

start: ## Run the container in background
	docker run -d --rm --privileged --name $(CONTAINER_NAME)-$(CONTAINER_INSTANCE) $(PORTS) $(VOLUMES) $(ENV) $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MICRO)

stop: ## Stop the container
	$(docker_stop)

test: ## Run all tests
	docker run \
		--rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(ROOT_FOLDER)/tests:/tests \
		gcr.io/gcp-runtimes/container-structure-test:latest \
			test \
			--image $(NS)/$(IMAGE_NAME):$(CURRENT_VERSION_MICRO) \
			--config /tests/config.yaml

release: build push ## Build and push the image to a registry

define docker_stop
	docker stop $(CONTAINER_NAME)-$(CONTAINER_INSTANCE)
endef