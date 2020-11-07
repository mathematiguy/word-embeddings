import click
import logging

import pandas as pd


def initialise_logger(log_level):
    global logger
    logger = logging.getLogger(__name__)
    log_fmt = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logging.basicConfig(level=log_level, format=log_fmt)
    return logger


@click.command()
@click.option('--sentence_csv', help='Path to sentences.csv')
@click.option('--corpus_file', help='Path to papers_corpus.txt')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(sentence_csv, corpus_file, log_level):

    global logger
    logger = initialise_logger(log_level)

    logger.info("Loading {}".format(sentence_csv))
    sentences = pd.read_csv(sentence_csv)

    logger.info("Writing corpus to: {}".format(corpus_file))
    with open(corpus_file, 'w') as f:
        for line in sentences.loc[sentences.phrase.str.len() > 0, 'phrase']:
            f.write(line + '\n')

if __name__ == '__main__':
    main()
