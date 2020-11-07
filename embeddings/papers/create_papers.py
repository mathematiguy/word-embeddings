import sys
sys.path.append("embeddings")

import json
import click
import pandas as pd

from utils import initialise_logger


def load_json(source):
    with open(source, 'r') as f:
        papers = pd.DataFrame(json.load(f))
        return papers
    logger.info('Loaded', source)

def create_papers(papers):

    col_patterns = {
        'newspaper': '([A-Z]+)[^/]+$',
        'issue': '[A-Z]+[0-9]+\.([^/]+)$',
        'year': '[A-Z]+([0-9]{4})[^/]+$',
        'month': '[A-Z]+[0-9]{4}([0-9]{2})[^/]+$',
        'day': '[A-Z]+[0-9]{6}([0-9]{2})[^/]+$'
    }

    logger.info('Extract newspaper, issue, year, month and day..')
    for col, pattern in col_patterns.items():
        papers[col] = papers.url.str.extract(pattern)

    papers = papers[[col for col in papers.columns if col != 'url']]

    return papers


@click.command()
@click.option('--source', help='Path to newspapers.json')
@click.option('--output', help='Path to papers.csv')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(source, output, log_level):

    global logger
    logger = initialise_logger(log_level, __file__)

    logger.info('Reading json from {}..'.format(source))
    papers = load_json(source)

    logger.info('Creating papers table..')
    papers = create_papers(papers)

    papers = papers.loc[papers.text.str.len() > 0, ['newspaper', 'issue', 'year', 'month', 'day', 'text']]

    logger.info('Write papers.csv to {}..'.format(output))
    papers.to_csv(output, index = False)

    logger.info('Done!')


if __name__ == '__main__':
    main()
