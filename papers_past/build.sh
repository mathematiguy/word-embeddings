#/bin/bash
set -ex

export RUN=

cd .. && make crawl

mv data/papers.json /output
