#! /bin/bash

set -ex

export RUN=

cd ..

# Send /input to data/papers directory
unzip /input/papers-past-embeddings/papers.zip -d .
unzip /input/papers-past-embeddings/te_ara.zip -d .

# Touch all dependencies for starmap
make data/te_ara/umap.csv -tB
make data/papers/umap.csv -tB

# Build the starmap front end
make starmap/dist/index.html

# Send dist/ folder to /publish
cp -r starmap/papers.json starmap/te_ara.json starmap/dist/* /publish

# Send dist/ folder to /output
cp -r starmap/dist/* /output
