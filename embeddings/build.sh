#/bin/bash
set -ex

export RUN=
export AUTOTUNE_DURATION=600

# Hyperparameters
export MIN_COUNT=30
export PHRASE_LENGTH=4
export MAX_N=6
export N_NEIGHBOURS=5
export MIN_DIST=0.8
export RADIUS=1000
export PRECISION=4

cd ..

cp /input/papers-past-crawler/newspapers.json data/papers

make all

zip /output/papers.zip data/papers/*
cp starmap/papers.json /output

zip /output/te_ara.zip data/te_ara/*
cp starmap/te_ara.json /output
