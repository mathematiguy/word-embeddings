DOCKER_REGISTRY := mathematiguy
IMAGE_NAME := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME)
RUN ?= docker run $(DOCKER_ARGS) --rm -v $$(pwd):/code -w $(WORK_DIR) -u $(UID):$(GID) $(IMAGE)
UID ?= $(shell id -u)
GID ?= $(shell id -g)
WORK_DIR ?= /code
DOCKER_ARGS ?=
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')
LOG_LEVEL ?= INFO
NUM_CORES ?= $(shell expr `grep -Pc '^processor\t' /proc/cpuinfo` - 1)
DATA_DIR ?= data
CORPUS_NAME ?= papers te_ara
API_TOKEN ?= $(shell cat credentials.json | jq '.[]' -r)

# Parameters
MIN_COUNT ?= 30  # Minimum number of occurrences to keep a word in the corpus
PHRASE_LENGTH ?= 4

.PHONY: starmap wordmap crawl shiny r_session jupyter ipython clean docker \
	docker-push docker-pull enter enter-root

.PRECIOUS: data/te_ara/corpus.txt data/te_ara/corpus.shuf data/te_ara/umap.csv data/te_ara/corpus.train data/te_ara/corpus.test data/te_ara/sentences.csv data/te_ara/fasttext_cbow.bin data/te_ara/word_counts.txt data/papers/corpus.txt data/papers/corpus.shuf data/papers/umap.csv data/papers/corpus.train data/papers/corpus.test data/papers/sentences.csv data/papers/fasttext_cbow.bin data/papers/word_counts.txt

all: $(addprefix starmap/,$(addsuffix .json,$(CORPUS_NAME)))

crawl: data/papers/newspapers.json
data/papers/newspapers.json:
	$(RUN) bash -c "cd papers_past && scrapy crawl papers \
		-o data/papers/newspapers.json \
		-a old_output=data/papers/newspapers.json \
		-a start_urls=start_urls.json \
		-L $(LOG_LEVEL)"

notebooks: $(shell ls -d analysis/*.Rmd | sed 's/.Rmd/.pdf/g')
data/te_ara/te-ara-mi-clean.txt: credentials.json
	wget `curl -X GET -k https://koreromaori.com/api/text/?format=json -H "Authorization: Token $(API_TOKEN)" | jq -c '.["results"][] | select( .id == 15) | .["cleaned_file"]' -r` -O $@ && touch $@

analysis/%.pdf: analysis/%.Rmd
	$(RUN) Rscript -e 'rmarkdown::render("$<")'

data/%/source.csv: embeddings/%/create_papers.py data/papers/newspapers.json
	$(RUN) python3 $< \
		--source data/papers/newspapers.json \
		--output $@ \
		--log_level $(LOG_LEVEL)

data/papers/paragraphs.csv: embeddings/papers/create_paragraphs.py data/papers/source.csv
	$(RUN) python3 $< \
		--papers_csv data/papers/source.csv \
		--paragraphs_csv $@ \
		--log_level $(LOG_LEVEL)

data/te_ara/paragraphs.csv: embeddings/te_ara/create_paragraphs.py data/te_ara/te-ara-mi-clean.txt
	$(RUN) python3 $< \
		--source data/te_ara/te-ara-mi-clean.txt \
		--paragraphs_csv $@ \
		--log_level $(LOG_LEVEL)

data/%/sentences.csv: embeddings/%/create_sentences.py data/%/paragraphs.csv
	$(RUN) python3 $< \
		--paragraphs_csv data/$*/paragraphs.csv \
		--sentences_csv $@ \
		--min_count $(MIN_COUNT) \
		--phrase_length $(PHRASE_LENGTH) \
		--log_level $(LOG_LEVEL)

data/%/corpus.txt: embeddings/create_corpus.py data/%/sentences.csv
	$(RUN) python3 $< --sentence_csv data/$*/sentences.csv \
		--corpus_file data/$*/corpus.txt \
		--log_level $(LOG_LEVEL)

data/%/corpus.shuf: data/%/corpus.txt
	cat $< | shuf > $@

data/%/corpus.train: data/%/corpus.shuf
	head $< -n $(shell expr `wc -l $< | awk '{print $$1}'` \* 8 / 10) > $@

data/%/corpus.test: data/%/corpus.shuf
	tail $< -n +$(shell expr `wc -l $< | awk '{print $$1}'` \* 8 / 10 + 1) > $@

MAX_N ?= 6
AUTOTUNE_DURATION ?= 30
data/%/fasttext_cbow.bin: data/%/corpus.train data/%/corpus.test
	$(RUN) fasttext cbow -input $< -output $(basename $@) -minCount $(MIN_COUNT) \
		-thread $(NUM_CORES) -autotune-duration $(AUTOTUNE_DURATION) -maxn $(MAX_N) \
		-autotune-validation data/$*/corpus.test

data/%/word_counts.txt: data/%/corpus.txt
	$(RUN) cat $< | grep -oE '[a-zāēīōū_]+' | sort | uniq -c | sort -nr | awk '($$1 >= $(MIN_COUNT))' > $@

N_NEIGHBOURS ?= 8
MIN_DIST ?= 0.8
data/%/umap.csv: embeddings/create_umap.py data/%/fasttext_cbow.bin data/%/word_counts.txt
	$(RUN) python3 $< --word_vectors data/$*/fasttext_cbow.vec \
		--word_counts data/$*/word_counts.txt --umap_file $@ \
		--n_neighbours $(N_NEIGHBOURS) --min_dist $(MIN_DIST) \
		--log_level $(LOG_LEVEL)

RADIUS ?= 1000
PRECISION ?= 4
starmap/%.json: embeddings/create_starmap.py data/%/umap.csv
	$(RUN) python3 $< --umap_csv data/$*/umap.csv --umap_json $@ --radius $(RADIUS) --precision $(PRECISION) --log_level $(LOG_LEVEL)

starmap/dist/index.html: UID=root
starmap/dist/index.html: GID=root
starmap/dist/index.html: starmap/te_ara.json
	$(RUN) sh -c 'cd starmap && npm i && npm run build'

starmap: UID=root
starmap: GID=root
starmap: DOCKER_ARGS=-p 8000:8000
starmap: starmap/dist/index.html
	$(RUN) sh -c 'cd starmap/dist && python3 -m http.server'

wordmap: DOCKER_ARGS=-p 8000:8000
wordmap: wordmap/papers/umap.csv wordmap/te_ara/umap.csv
	$(RUN) sh -c 'cd wordmap/ && python3 -m http.server'

wordmap/%/umap.csv: data/%/umap.csv
	cp -r wordmap/D3 $(dir $@) && cp $< $@

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
	rm -rf data/te_ara/* && find data/papers/ -type f | grep -v papers.json | xargs rm -f

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
