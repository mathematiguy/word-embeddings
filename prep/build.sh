#/bin/bash
set -ex

export RUN=

cd ..

mv /input/papers-past-crawler/newspapers.json data

make data/papers.csv

mv data/papers.csv /output
