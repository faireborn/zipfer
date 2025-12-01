#! /bin/bash

spm_train \
  --input=./data/minipile/data/minipile.txt \
  --model_prefix=./data/minipile/data/trained/unigram_10k \
  --vocab_size=10000 \
  --input_sentence_size=1000000 \
  --shuffle_input_sentence=true
