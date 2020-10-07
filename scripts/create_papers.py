import os
import re
import json
import click
import logging
import itertools

import numpy as np
import pandas as pd

from functools import partial
from itertools import product
from collections import Counter
from unicodedata import category
from multiprocessing import cpu_count
from utils import multicore_apply

from reo_toolkit import is_maori
from gensim.models import Phrases
from nltk.tokenize import word_tokenize, sent_tokenize


def initialise_logger(log_level):
    global logger
    logger = logging.getLogger(__name__)
    log_fmt = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logging.basicConfig(level=log_level, format=log_fmt)
    return logger


def load_json(papers_json):
    with open(papers_json, 'r') as f:
        papers = pd.DataFrame(json.load(f))
        return papers
    logger.info('Loaded', papers_json)

def extract_words(text):
    text = text.lower()
    results = []
    for word in word_tokenize(text):
        if re.search('[a-zāēīōū]', word):
            result = re.sub('\s{2,}', ' ',
                re.sub('[^a-zāēīōū]', ' ', word)
            )
            for res in result.split():
                results.append(res)
    return results

def phrase_model(lines, min_count, threshold, phrase_length):

    for _ in range(phrase_length):
        sentence_stream = [doc.split(" ") for doc in lines]
        bigram = Phrases(sentence_stream, min_count=min_count, threshold=threshold)
        lines = [' '.join(bigram[line.split()]) for line in lines]

    return lines

def create_papers(papers):

    col_patterns = {
        'newspaper_id': '([A-Z]+)[^/]+$',
        'year': '[A-Z]+([0-9]{4})[^/]+$',
        'month': '[A-Z]+[0-9]{4}([0-9]{2})[^/]+$',
        'day': '[A-Z]+[0-9]{6}([0-9]{2})[^/]+$',
        'id': '[A-Z]+[0-9]+\.([^/]+)$'
    }

    logger.info('Extract newspaper_id, year, month and day..')
    for col, pattern in col_patterns.items():
        papers[col] = papers.url.str.extract(pattern)

    logger.info('Split text into paragraphs..')
    papers['paragraph'] = papers.text.apply(lambda s: s.split("\n"))
    papers = papers.explode('paragraph')

    logger.info('Split paragraphs into sentences..')
    papers['sentence'] = multicore_apply(papers.paragraph, sent_tokenize)
    papers = papers.explode('sentence')
    papers = papers[~papers.sentence.isna()]

    logger.info('Split sentences into words..')
    papers['words'] = multicore_apply(papers['sentence'], extract_words)

    maori_words  = set(word for word in
        papers.loc[papers.words.apply(len) > 0, 'words']
              .explode()
              .unique()
       if is_maori(word, strict=True)
    )
    non_maori_words  = set(word for word in
        papers.loc[papers.words.apply(len) > 0, 'words']
              .explode()
              .unique()
        if not is_maori(word, strict=True)
    )

    logger.info('Extract non-māori phrases')
    papers['discarded_phrase'] = phrase_model(
        papers.words
              .apply(lambda x: ' '.join(
                   [y for y in x if y in non_maori_words]
              )),
        min_count = 30,
        threshold = 10,
        phrase_length = 5
    )

    logger.info('Extract māori phrases')
    papers['phrase'] = phrase_model(
        (papers.words
            .apply(lambda x: ' '.join(
                [y for y in x if y in maori_words]
            ))),
        min_count = 30,
        threshold = 10,
        phrase_length = 5
    )

    papers = papers.loc[~papers.phrase.isna(), :]

    return papers


@click.command()
@click.option('--papers_json', help='Path to newspapers.json')
@click.option('--papers_csv', help='Path to papers.csv')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(papers_json, papers_csv, log_level):

    global logger
    logger = initialise_logger(log_level)

    papers = load_json(papers_json)
    papers = create_papers(papers)

    papers.to_csv(papers_csv, index = False)


if __name__ == '__main__':
    main()
