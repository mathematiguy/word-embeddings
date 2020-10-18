import re
import json
import click
import numpy as np
import pandas as pd
from utils import initialise_logger, multicore_apply

from umap import UMAP


def create_vector_data(word_vectors):

    with open(word_vectors, 'r') as f:

        vector_data = f.read().strip().split('\n')
        rows, dims = vector_data[0].split()

        vector_data = [(word, [float(v) for v in vec.split()])
                       for word, vec in map(lambda s: s.split(' ', 1), vector_data[1:])]
        vector_data = pd.DataFrame(vector_data)

        vector_data.columns = ['word', 'vector']

        return vector_data


def create_word_counts(word_counts):

    result = []
    with open(word_counts, 'r') as f:
        for line in f.read().strip().split('\n'):
            count, word = line.strip().split()
            result.append({'word': word, 'count': count})

    return pd.DataFrame.from_dict(result)


def calculate_umap(params, umap_data, similarity_matrix):
    neighbors, dist = params

    reducer = UMAP(n_neighbors = neighbors, min_dist = dist)
    reduced = reducer.fit_transform(similarity_matrix)

    umap_data['n_neighbors'] = neighbors
    umap_data['min_dist'] = dist

    umap_data['x'] = reduced[:, 0]
    umap_data['y'] = reduced[:, 1]

    umap_data = umap_data[['n_neighbors', 'min_dist', 'word', 'count', 'x', 'y']]

    umap_data['rank'] = np.arange(len(umap_data))

    umap_data = umap_data[umap_data.word != '</s>']

    umap_data.columns = ['n_neighbors', 'min_dist', 'word', 'word_count', 'x_coord', 'y_coord', 'rank']

    return umap_data


def create_umap_json(umap_data):

    umap_json = []
    for i, row in umap_data.iterrows():
        umap_json.append({
            'word': row['word'],
            'position': [row['x_coord'], row['y_coord']],
            'rank': row['rank'],
            'count': row['word_count']

        })
    return umap_json


@click.command()
@click.option('--word_vectors', help='Path to fasttext.vec')
@click.option('--word_counts', help='Path to word_counts.txt')
@click.option('--umap_file', help='Path to save umap.json')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(word_vectors, word_counts, umap_file, log_level):

    global logger
    logger = initialise_logger(log_level, __file__)

    logger.info('Creating vector_data..')
    vector_data = create_vector_data(word_vectors)
    word_counts = create_word_counts(word_counts)
    vector_data = vector_data.merge(word_counts, on = 'word', how = 'inner')

    logger.info('Computing similarity matrix..')
    word_vectors = np.vstack(vector_data.vector)
    similarity_matrix = np.dot(word_vectors, word_vectors.transpose())

    logger.info('Running umap model..')
    n_neighbours = 4
    min_dist = 0.8
    umap_data = calculate_umap([n_neighbours, min_dist], vector_data, similarity_matrix)

    logger.info("Saving output to {}".format(umap_file))
    umap_json = create_umap_json(umap_data)
    with open(umap_file, 'w') as f:
        f.write(json.dumps(umap_json))

    logger.info('Done!')


if __name__ == '__main__':
    main()
