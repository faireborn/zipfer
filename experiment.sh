#! /bin/bash

spm_train --input=./data/minipile/data/minipile.txt --model_prefix=unigram_10k --vocab_size=10000 --input_sentence_size=1000000 --shuffle_input_sentence=true
spm_encode --model=unigram_10k.model --input=./data/minipile/data/minipile.txt --output=./data/minipile/data/encoded/unigram_10k.txt
