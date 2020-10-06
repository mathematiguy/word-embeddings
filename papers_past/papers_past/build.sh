#/bin/bash

set -ex

make crawl

mv data/newspapers.json /output
