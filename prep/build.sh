#/bin/bash
set -ex

export RUN=
export DATA_DIR=/input/papers-past-crawler

cd ..

make ${DATA_DIR}/model_data.csv

# Show file sizes for output
du -sh ${DATA_DIR}/*

mv ${DATA_DIR}/papers_corpus.txt ${DATA_DIR}/model_data.csv /output

zip /output/papers.zip ${DATA_DIR}/papers.csv
zip /output/fasttext.zip ${DATA_DIR}/fasttext.bin
