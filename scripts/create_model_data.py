import click
import logging

import fasttext
import pandas as pd
from utils import initialise_logger

def build_model_data(model):

    model_data = pd.DataFrame({'word': model.words})
    model_data = model_data[model_data.word != '</s>']
    model_data['word_vector'] = model_data.word.apply(model.get_word_vector)
    return model_data

@click.command()
@click.option('--model_file', help='Path to save the fasttext model')
@click.option('--log_level', default='INFO', help='Log level (default: INFO)')
def main(model_file, log_level):

    global logger
    logger = initialise_logger(log_level)

    model = fasttext.load_model(model_file)
    model_data = build_model_data(model)

    print(model_data)


if __name__ == '__main__':
    main()
