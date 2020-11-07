import re
import json
import click
import numpy as np
import pandas as pd
from scipy.linalg import norm
from utils import initialise_logger, multicore_apply

from umap import UMAP


def create_vector_data(word_vectors):

    with open(word_vectors, 'r') as f:

        vector_data = f.read().strip().split('\n')
        rows, dims = vector_data[0].split()

        vector_data = [(word, np.array([float(v) for v in vec.split()]))
                       for word, vec in map(lambda s: s.split(' ', 1), vector_data[1:])]
        vector_data = pd.DataFrame(vector_data)

        vector_data.columns = ['word', 'vector']

        return vector_data


def create_word_counts(word_counts):

    result = []
    with open(word_counts, 'r') as f:
        for line in f.read().strip().split('\n'):
            count, word = line.strip().split()
            result.append({'word': word, 'count': int(count)})

    return pd.DataFrame.from_dict(result)


def calculate_umap(params, umap_data, similarity_matrix):
    neighbors, dist = params

    reducer = UMAP(n_neighbors = neighbors, min_dist = dist, random_state = 42)
    reduced = reducer.fit_transform(similarity_matrix)

    umap_data['n_neighbors'] = neighbors
    umap_data['min_dist'] = dist

    umap_data['x'] = reduced[:, 0]
    umap_data['y'] = reduced[:, 1]

    umap_data['x'] = umap_data['x'] / (umap_data.x.max() - umap_data.x.min())
    umap_data['y'] = umap_data['y'] / (umap_data.y.max() - umap_data.y.min())

    umap_data = umap_data[['n_neighbors', 'min_dist', 'word', 'count', 'x', 'y']]

    umap_data['rank'] = np.arange(len(umap_data))

    umap_data = umap_data[umap_data.word != '</s>']

    umap_data['x'] = umap_data.x - umap_data.x.mean()
    umap_data['y'] = umap_data.y - umap_data.y.mean()

    umap_data.columns = ['n_neighbors', 'min_dist', 'word', 'word_count', 'x_coord', 'y_coord', 'rank']

    return umap_data


@click.command()
@click.option('--word_vectors', help='Path to fasttext.vec')
@click.option('--word_counts', help='Path to word_counts.txt')
@click.option('--umap_file', help='Path to save umap.json')
@click.option('--n_neighbours', type=int, help='This parameter controls how UMAP balances local versus global structure in the data.')
@click.option('--min_dist', type=float, help='Controls how tightly UMAP is allowed to pack points together')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(word_vectors, word_counts, umap_file, n_neighbours, min_dist, log_level):

    global logger
    logger = initialise_logger(log_level, __file__)

    logger.info('Creating vector_data..')
    vector_data = create_vector_data(word_vectors)
    word_counts = create_word_counts(word_counts)
    vector_data = vector_data.merge(word_counts, on = 'word', how = 'inner')

    logger.info('Computing similarity matrix..')
    normalize = lambda x: x / norm(x)
    word_vectors = np.vstack(vector_data.vector.apply(normalize))
    similarity_matrix = np.dot(word_vectors, word_vectors.transpose())

    logger.info('Running umap model..')
    umap_data = calculate_umap([n_neighbours, min_dist], vector_data, similarity_matrix)

    logger.info('Saving output to {}'.format(umap_file))
    umap_data.to_csv(umap_file, index = False)

    logger.info('Done!')


if __name__ == '__main__':
    main()
