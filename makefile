DOCKER_REGISTRY := docker.dragonfly.co.nz
IMAGE_NAME := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME)
RUN ?= docker run $(DOCKER_ARGS) --rm -v $$(pwd):/work -w /work -u $(UID):$(GID) $(IMAGE)
UID ?= $(shell id -u)
GID ?= $(shell id -g)
DOCKER_ARGS ?= 
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')

JUPYTER_PASSWORD ?= jupyter
JUPYTER_PORT ?= 8888
.PHONY: jupyter
jupyter: UID=root
jupyter: GID=root
jupyter: DOCKER_ARGS=-u $(UID):$(GID) --rm -it -p $(JUPYTER_PORT):$(JUPYTER_PORT) -e NB_USER=$$USER -e NB_UID=$(UID) -e NB_GID=$(GID)
jupyter:
	$(RUN) jupyter lab \
		--allow-root \
		--port $(JUPYTER_PORT) \
		--ip 0.0.0.0 \
		--NotebookApp.password=$(shell $(RUN) \
			python3 -c \
			"from IPython.lib import passwd; print(passwd('$(JUPYTER_PASSWORD)'))")

.PHONY: docker
docker:
	docker build $(DOCKER_ARGS) --tag $(IMAGE):$(GIT_TAG) .
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

.PHONY: docker-push
docker-push:
	docker push $(IMAGE):$(GIT_TAG)
	docker push $(IMAGE):latest

.PHONY: docker-pull
docker-pull:
	docker pull $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

.PHONY: enter
enter: DOCKER_ARGS=-it
enter:
	$(RUN) bash

.PHONY: enter-root
enter-root: DOCKER_ARGS=-it
enter-root: UID=root
enter-root: GID=root
enter-root:
	$(RUN) bash

.PHONY: inspect-variables
inspect-variables:
	@echo DOCKER_REGISTRY: $(DOCKER_REGISTRY)
	@echo IMAGE_NAME:      $(IMAGE_NAME)
	@echo IMAGE:           $(IMAGE)
	@echo RUN:             $(RUN)
	@echo UID:             $(UID)
	@echo GID:             $(GID)
	@echo DOCKER_ARGS:     $(DOCKER_ARGS)
	@echo GIT_TAG:         $(GIT_TAG)
