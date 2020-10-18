#/bin/bash
set -ex

export RUN=

cd ..

make notebooks

cp analysis/network_modelling.pdf /output
