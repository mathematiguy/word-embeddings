#! /bin/bash

set -ex

export RUN=

cd ..

# Send /input to data/papers directory
cp /input/papers-past-embeddings/umap.json data/papers/

ls data/papers

# Build the starmap front end
make starmap -d

# Show the starmap directory
ls starmap

# Send dist/ folder to /publish
cp -r starmap/dist/* /publish
