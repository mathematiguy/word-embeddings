#/bin/bash
set -ex

export RUN=

cd ..

ls /input

mv /input/newspapers.json data

make data/papers.csv

mv data/papers.csv /output
