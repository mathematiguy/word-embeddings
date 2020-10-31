#! /bin/bash

set -ex

cd ..

unzip /input/papers-past-embeddings/papers.zip -d data/papers
unzip /input/papers-past-embeddings/te_ara.zip -d data/te_ara

tree data

make wordmap -tB
make wordmap

cp -r papers te_ara /publish
