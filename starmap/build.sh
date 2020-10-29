#! /bin/bash

set -ex

export RUN=

cd ..

# Send /input to data/papers directory
unzip /input/papers-past-embeddings/papers.zip -d .
unzip /input/papers-past-embeddings/te_ara.zip -d .

# Show everything in data/papers
tree data

# Touch all dependencies for starmap
make starmap/te_ara.json -tB

# Build the starmap front end
make starmap/dist/index.html

# Send dist/ folder to /publish
cp -r starmap/dist/* /publish

# Send dist/ folder to /output
cp -r starmap/dist/* /output
