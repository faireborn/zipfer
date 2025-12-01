#! /bin/bash

mkdir -p ./data/minipile/data/encoded ./data/minipile/data/spm

spm_train --input=./data/minipile/data/minipile.txt --model_prefix=./data/minipile/data/spm/unigram_10k --vocab_size=10000 --input_sentence_size=1000000 --shuffle_input_sentence=true
spm_encode --model=./data/minipile/data/spm/unigram_10k.model --input=./data/minipile/data/minipile.txt --output=./data/minipile/data/encoded/unigram_10k.txt
