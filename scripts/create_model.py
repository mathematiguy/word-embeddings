import click
import logging

import fasttext
from utils import initialise_logger

@click.command()
@click.option('--corpus_file', help='Path to papers_corpus.txt')
@click.option('--model_file', help='Path to save the fasttext model')
@click.option('--min_count', default=30, type=int, help='Minimal number of word occurences')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(corpus_file, model_file, min_count, log_level):

    global logger
    logger = initialise_logger(log_level)

    model = fasttext.train_unsupervised(corpus_file, minCount = min_count)
    model.save_model(model_file)


if __name__ == '__main__':
    main()
