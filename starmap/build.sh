#! /bin/bash

set -ex

export RUN=

cd ..

# Send /input to data/papers directory
cp /input/papers-past-embeddings/* data/papers/

# Build the starmap front end
make starmap

# Send dist/ folder to /publish
cp starmap/dist/* /publish
