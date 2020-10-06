#/bin/bash

set -ex

cd ..

make crawl

mv data/newspapers.json /output
