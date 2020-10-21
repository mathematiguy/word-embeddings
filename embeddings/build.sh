#/bin/bash
set -ex

export RUN=
export MIN_COUNT=30
export AUTOTUNE_DURATION=600

# Hyperparameters
export MAX_N=6  # default: 6
export N_NEIGHBOURS=5
export MIN_DIST=0.8

cd ..

cp /input/papers-past-crawler/papers.json data/papers

make all

# Show file sizes for output
du -sh data/papers/*

mv data/papers/corpus.txt data/papers/corpus.train \
   data/papers/corpus.test data/papers/word_counts.txt \
   data/papers/fasttext_cbow.bin data/papers/fasttext_cbow.vec \
   data/papers/*.csv starmap/starmap.json /output
