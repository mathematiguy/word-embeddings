# Import libraries
library(tidyverse)
library(fastrtext)
library(stringi)
library(igraph)
library(furrr)
library(here)

# Use furr multiprocessing
plan(multiprocess)

model = fastrtext::load_model(here('data/papers/fasttext_cbow.bin'))
sentences = read_csv(here('data/papers/sentences.csv'))
word_counts = read_table('data/papers/word_counts.txt', col_names = c('count', 'word'))

path_examples = read_csv(here('data/papers/path_examples.csv'))

get_shortest_path <- function(x, y) {
    paste(names(shortest_paths(G, x, y)$vpath[[1]]), collapse = ' ')
}

path_examples %>%
    mutate_all(function(x) str_replace_all(str_to_lower(x), ' ', '_')) %>%
    mutate_all(function(x) str_replace_all(x, '\\-', '')) %>%
    mutate_all(function(x) stri_trans_general(str = x, id = "Latin-ASCII")) %>%
    mutate(in_vocab_1 = kupu_1 %in% V(G)$name,
           in_vocab_2 = kupu_2 %in% V(G)$name) %>%
    filter(in_vocab_1 & in_vocab_2) %>%
    mutate(path = map2_chr(kupu_1, kupu_2, get_shortest_path)) %>%
    mutate(path_length = str_count(path, ' ')) %>%
    select(-in_vocab_1, -in_vocab_2) %>%
    write_csv(here('data/papers/calculated_paths.csv'))
