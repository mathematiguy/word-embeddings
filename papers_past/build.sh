#/bin/bash
set -ex

export RUN=

cd .. && make crawl

mv data/papers/papers.json /output
