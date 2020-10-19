#! /bin/bash

set -ex

export RUN=
export MIN_COUNT=30
export AUTOTUNE_DURATION=600

# Hyperparameters
export MAX_N=6  # default: 6

cd ..

# Send /input to data/papers directory
cp /input/papers-past-crawler/papers.json data/papers/
cp /input/papers-past-embeddings/* data/papers/

ls -la data/papers

# Build the starmap front end
make starmap -o

# Show the starmap directory
ls starmap

# Send dist/ folder to /publish
cp -r starmap/dist/* /publish
