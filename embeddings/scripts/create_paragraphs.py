import click
import pandas as pd
from utils import initialise_logger


def create_paragraphs(paragraphs):

    paragraphs['paragraph'] = paragraphs.text.apply(lambda s: s.split("\n"))
    paragraphs = paragraphs[[col for col in paragraphs.columns if not col == 'text']].explode('paragraph')
    paragraphs = paragraphs[paragraphs.paragraph.str.len() > 0].drop_duplicates()

    group_vars = ['newspaper', 'issue', 'year', 'month', 'day', 'paragraph']
    paragraphs['paragraph_id'] = paragraphs.groupby(group_vars).ngroup()
    paragraphs['paragraph_id'] = paragraphs.paragraph_id - \
        (paragraphs
             .groupby(['newspaper', 'issue', 'year', 'month', 'day'],
                      group_keys = False)
             .transform(min)
             ['paragraph_id'])

    return (paragraphs
        .sort_values(['newspaper', 'issue', 'year', 'month', 'day', 'paragraph_id'])
        [['newspaper', 'issue', 'year', 'month', 'day', 'paragraph_id', 'paragraph']]
        )


@click.command()
@click.option('--papers_csv', help='Path to papers.csv')
@click.option('--paragraphs_csv', help='Path to paragraphs.csv')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(papers_csv, paragraphs_csv, log_level):

    global logger
    logger = initialise_logger(log_level, __file__)

    logger.info('Reading {}..'.format(papers_csv))
    papers = pd.read_csv(papers_csv)
    assert not papers.text.isna().any()

    logger.info('Split text into paragraphs..')
    paragraphs = create_paragraphs(papers)

    logger.info('Save paragraphs to {}..'.format(paragraphs_csv))
    paragraphs.to_csv(paragraphs_csv, index = False)

    logger.info('Done!')


if __name__ == '__main__':
    main()
