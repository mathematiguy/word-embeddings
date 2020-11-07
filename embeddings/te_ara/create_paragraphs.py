import sys
sys.path.append("embeddings")

import click
import pandas as pd
from utils import initialise_logger


def create_paragraphs(paragraphs):

    paragraphs['paragraph'] = paragraphs.text.apply(lambda s: s.split("\n"))
    paragraphs = paragraphs[[col for col in paragraphs.columns if not col == 'text']].explode('paragraph')
    paragraphs = paragraphs[paragraphs.paragraph.str.len() > 0].drop_duplicates()

    return paragraphs


@click.command()
@click.option('--source', help='Path to te_ara.csv')
@click.option('--paragraphs_csv', help='Path to paragraphs.csv')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(source, paragraphs_csv, log_level):

    global logger
    logger = initialise_logger(log_level, __file__)

    logger.info('Reading {}..'.format(source))
    te_ara = pd.DataFrame(columns = ['text'])
    with open(source, 'r') as f:
        te_ara['text'] = [f.read()]

    logger.info('Split text into paragraphs..')
    paragraphs = create_paragraphs(te_ara)

    logger.info('Save paragraphs to {}..'.format(paragraphs_csv))
    paragraphs.to_csv(paragraphs_csv, index = False)

    logger.info('Done!')


if __name__ == '__main__':
    main()
