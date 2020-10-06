DOCKER_REGISTRY := mathematiguy
IMAGE_NAME := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME)
RUN ?= docker run $(DOCKER_ARGS) --rm -v $$(pwd):/code -w /code -u $(UID):$(GID) $(IMAGE)
UID ?= $(shell id -u)
GID ?= $(shell id -g)
DOCKER_ARGS ?= 
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')
LOG_LEVEL ?= INFO

.PHONY: web_server crawl notebooks shiny r_session jupyter ipython clean docker \
	docker-push docker-pull enter enter-root

web_server: PORT=-p 8000:8000
web_server:
	(cd D3 && $(RUN_IMAGE) python3 -m http.server)

crawl:
	$(RUN) bash -c "cd papers_past && scrapy crawl papers \
		-o ../data/newspapers.json \
		-a old_output=../data/newspapers.json \
		-a start_urls=../start_urls.json \
		-L $(LOG_LEVEL)"

notebooks: $(shell ls -d analysis/*.Rmd | sed 's/.Rmd/.pdf/g')

analysis/%.pdf: analysis/%.Rmd
	$(RUN) Rscript -e 'rmarkdown::render("$<")'

shiny: DOCKER_ARGS= -p 7727:7727
shiny:
	$(RUN) Rscript shiny/global.R

r_session: DOCKER_ARGS= -dit --rm -e DISPLAY=$$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:ro --name="rdev"
r_session:
	$(RUN) R

JUPYTER_PASSWORD ?= jupyter
JUPYTER_PORT ?= 8888
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

ipython: DOCKER_ARGS=-it
ipython:
	$(RUN) ipython --no-autoindent

clean:
	rm -rf data/output.json data/old_output.json

docker:
	docker build $(DOCKER_ARGS) --tag $(IMAGE):$(GIT_TAG) .
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

docker-push:
	docker push $(IMAGE):$(GIT_TAG)
	docker push $(IMAGE):latest

docker-pull:
	docker pull $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

enter: DOCKER_ARGS=-it
enter:
	$(RUN) bash

enter-root: DOCKER_ARGS=-it
enter-root: UID=root
enter-root: GID=root
enter-root:
	$(RUN) bash
