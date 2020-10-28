#! /bin/bash

set -ex

export RUN=

cd ..

# Send /input to data/papers directory
cp /input/papers-past-crawler/newspapers.json data/papers/
cp /input/papers-past-embeddings/papers.json starmap/

unzip /input/papers-past-embeddings/papers.zip -d data/papers/
unzip /input/papers-past-embeddings/te_ara.zip -d data/papers/

# Show everything in data/papers
tree data

# Touch all dependencies for starmap
make starmap/starmap.json -tB

# Build the starmap front end
make starmap/dist/index.html

# Send dist/ folder to /publish
cp -r starmap/dist/* /publish

# Send dist/ folder to /output
cp -r starmap/dist/* /output
