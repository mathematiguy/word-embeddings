#! /bin/bash

set -ex

export RUN=

cd ..

unzip /input/papers-past-embeddings/papers.zip -d .
unzip /input/papers-past-embeddings/te_ara.zip -d .

tree data

make wordmap/papers/umap.csv -tB
make wordmap/te_ara/umap.csv -tB

cp -r papers te_ara /publish
