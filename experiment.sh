#! /bin/bash

mkdir -p \
  ./data/minipile/data/trained \
  ./data/minipile/data/encoded \
  ./results

printf "Training tokenizers...\n"
./tokenizer_train.sh ||
  {
    echo "Error while training tokenizers!"
    exit 1
  }

printf "\n\nTokenizing corpus...\n"
./tokenizer_encode.sh ||
  {
    echo "Error while tokenizing corpus!"
    exit 1
  }

printf "\n\nEvaluating tokenizers...\n"
./zipfer.sh ||
  {
    echo "Error while evaluating tokenizers!"
    exit 1
  }

printf "\n\nDone!\n"
