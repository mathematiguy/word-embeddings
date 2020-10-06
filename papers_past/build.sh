#/bin/bash
set -ex

export RUN=

cd .. && make crawl

mv data/newspapers.json /output
