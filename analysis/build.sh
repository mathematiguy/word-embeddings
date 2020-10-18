#/bin/bash
set -ex

export RUN=

cd ..
cp /input/papers-past-embeddings/* data/

make notebooks

cp analysis/network_modelling.pdf /output
