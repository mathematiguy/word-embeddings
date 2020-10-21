#! /bin/bash

set -ex

export RUN=

cd ..

# Send /input to data/papers directory
cp /input/papers-past-crawler/papers.json data/papers/
cp /input/papers-past-embeddings/starmap.json starmap/
cp /input/papers-past-embeddings/* data/papers/

# Show everything in data/papers
ls -la data/papers

# Touch all dependencies for starmap
make starmap -tB

# Build the starmap front end
make starmap

# Show the starmap directory
ls starmap

# Send dist/ folder to /publish
cp -r starmap/dist/* /publish

# Send dist/ folder to /output
cp -r starmap/dist/* /output
