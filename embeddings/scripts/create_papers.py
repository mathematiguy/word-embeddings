import json
import click
import pandas as pd

from utils import initialise_logger


def load_json(papers_json):
    with open(papers_json, 'r') as f:
        papers = pd.DataFrame(json.load(f))
        return papers
    logger.info('Loaded', papers_json)

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
@click.option('--papers_json', help='Path to newspapers.json')
@click.option('--papers_csv', help='Path to papers.csv')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(papers_json, papers_csv, log_level):

    global logger
    logger = initialise_logger(log_level, __file__)

    logger.info('Reading json from {}..'.format(papers_json))
    papers = load_json(papers_json)

    logger.info('Creating papers table..')
    papers = create_papers(papers)

    papers = papers.loc[papers.text.str.len() > 0, ['newspaper', 'issue', 'year', 'month', 'day', 'text']]

    logger.info('Write papers.csv to {}..'.format(papers_csv))
    papers.to_csv(papers_csv, index = False)

    logger.info('Done!')


if __name__ == '__main__':
    main()
