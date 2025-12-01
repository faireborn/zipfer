#! /bin/bash

mkdir -p ./result

./zig-out/bin/zipfer --vocab=./data/minipile/data/spm/unigram_10k.vocab --target=./data/minipile/data/encoded/unigram_10k.txt --output=./result/unigram_10k
