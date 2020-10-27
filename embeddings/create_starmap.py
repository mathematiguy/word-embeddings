import re
import json
import click
import numpy as np
import pandas as pd
from utils import initialise_logger, multicore_apply, calculate_distance_matrix

from umap import UMAP


def get_z_coordinate(x, y):

    norm = np.sqrt(x ** 2 + y ** 2)
    if norm > 1:
        x = x / norm
        y = y / norm
    return np.sqrt(1 - x ** 2 - y ** 2)


def create_umap_json(umap_data, radius, precision):
    print(radius, precision)
    umap_json = {'data': []}
    for i, row in umap_data.iterrows():
        umap_json['data'].append({
            'word': row['word'],
            'position': [round(row['x_coord'] * radius, precision),
                         round(get_z_coordinate(row['x_coord'], row['y_coord']) * radius, precision),
                         round(row['y_coord'] * radius, precision)],
            'rank': row['rank'],
            'count': row['word_count']

        })
    return umap_json


def rescale_point_map(umap_data):

    U = umap_data[['x_coord', 'y_coord']].values


    norms = calculate_distance_matrix(U, np.array([[0,0]]))
    U = U * np.log(norms)

    # Scale point map so max_distance is 1
    radius = np.max(calculate_distance_matrix(U, U)) / 2
    U = U / radius

    # Scale point map to set max_norm == 1
    norms = calculate_distance_matrix(U, np.array([[0,0]]))
    U = U / np.max(norms)

    norms = calculate_distance_matrix(U, np.array([[0,0]]))

    umap_data['x_coord'] = U[:,0]
    umap_data['y_coord'] = U[:,1]

    return umap_data


@click.command()
@click.option('--umap_csv', help='Path to umap.csv')
@click.option('--umap_json', help='Path to save umap.json')
@click.option('--radius', type=float, help='Sets the radius of the point map in 3 dimensions')
@click.option('--precision', type=int, help='Sets the floating point precision of the point data')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(umap_csv, umap_json, radius, precision, log_level):

    global logger
    logger = initialise_logger(log_level, __file__)

    logger.info("Reading umap_data from {}".format(umap_csv))
    umap_data = pd.read_csv(umap_csv)

    logger.info('Rescaling point map..')
    umap_data = rescale_point_map(umap_data)

    logger.info("Saving output to {}".format(umap_json))
    starmap_json = create_umap_json(umap_data, radius, precision)
    with open(umap_json, 'w') as f:
        f.write(json.dumps(starmap_json))

    logger.info('Done!')


if __name__ == '__main__':
    main()
