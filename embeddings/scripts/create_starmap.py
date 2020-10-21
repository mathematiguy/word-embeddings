import re
import json
import click
import numpy as np
import pandas as pd
from utils import initialise_logger, multicore_apply

from umap import UMAP


def create_umap_json(umap_data):

    precis = 4
    scale = 1000
    umap_json = {'data': []}
    for i, row in umap_data.iterrows():
        umap_json['data'].append({
            'word': row['word'],
            'position': [round(row['x_coord'] * scale, precis),
                         round(np.sqrt(1 - row['x_coord'] ** 2 - row['y_coord'] ** 2) * scale, precis),
                         round(row['y_coord'] * scale, precis)],
            'rank': row['rank'],
            'count': row['word_count']

        })
    return umap_json


@click.command()
@click.option('--umap_csv', help='Path to umap.csv')
@click.option('--umap_json', help='Path to save umap.json')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(umap_csv, umap_json, log_level):

    global logger
    logger = initialise_logger(log_level, __file__)

    logger.info("Reading umap_data from {}".format(umap_csv))
    umap_data = pd.read_csv(umap_csv)

    logger.info("Saving output to {}".format(umap_json))
    starmap_json = create_umap_json(umap_data)
    with open(umap_json, 'w') as f:
        f.write(json.dumps(starmap_json))

    logger.info('Done!')


if __name__ == '__main__':
    main()
