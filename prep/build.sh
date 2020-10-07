#/bin/bash
set -ex

export RUN=
export DATA_DIR=/input/papers-past-crawler

cd ..

make ${DATA_DIR}/model_data.csv

mv ${DATA_DIR}/papers.csv \
   ${DATA_DIR}/papers_corpus.txt \
   ${DATA_DIR}/model_data.csv \
   /output

zip /output/fasttext.zip \
    ${DATA_DIR}/fasttext.bin
