#/bin/bash
set -ex

export RUN=

cd ..

cp /input/papers-past-crawler data/papers

make all

# Show file sizes for output
du -sh ${DATA_DIR}/*

mv ${DATA_DIR}/corpus.txt ${DATA_DIR}/corpus.train \
   ${DATA_DIR}/corpus.test ${DATA_DIR}/word_counts.txt \
   /output

zip /output/papers.zip ${DATA_DIR}/papers.csv
zip /output/fasttext.zip ${DATA_DIR}/fasttext_cbow.bin ${DATA_DIR}/fasttext_cbow.vec
