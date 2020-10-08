#/bin/bash
set -ex

export RUN=
export DATA_DIR=/input/papers-past-crawler

cd ..

make ${DATA_DIR}/model_data.csv

mv ${DATA_DIR}/papers.csv \
   ${DATA_DIR}/corpus.txt \
   ${DATA_DIR}/fasttext_cbow.bin \
   ${DATA_DIR}/fasttext_cbow.vec \
   /output
