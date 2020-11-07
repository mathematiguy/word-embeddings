#/bin/bash
set -ex

export RUN=

cd .. && make crawl

mv data/papers/newspapers.json /output
