#! /bin/bash

set -ex

export RUN=

cd ..

unzip /input/papers-past-embeddings/papers.zip -d .
unzip /input/papers-past-embeddings/te_ara.zip -d .

tree data

make data/papers/umap.csv -tB
make data/te_ara/umap.csv -tB

make wordmap/papers/umap.csv
make wordmap/te_ara/umap.csv

cp -r wordmap/papers wordmap/te_ara /publish
