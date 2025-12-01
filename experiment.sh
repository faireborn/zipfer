#! /bin/bash

ALGORITHM_LIST=(
  "unigram"
)

VOCAB_SIZE_LIST=(
  "30000"
)

mkdir -p \
  ./data/minipile/data/trained \
  ./data/minipile/data/encoded \
  ./results

printf "Training tokenizers...\n"

for ALGORITHM in "${ALGORITHM_LIST[@]}"; do
  for VOCAB_SIZE in "${VOCAB_SIZE_LIST[@]}"; do
    ./tokenizer_train.sh -a ${ALGORITHM} -s ${VOCAB_SIZE} ||
      {
        echo "Error while training tokenizers!"
        exit 1
      }
  done
done

printf "\n\nTokenizing corpus...\n"
for ALGORITHM in "${ALGORITHM_LIST[@]}"; do
  for VOCAB_SIZE in "${VOCAB_SIZE_LIST[@]}"; do
    ./tokenizer_encode.sh -a ${ALGORITHM} -s ${VOCAB_SIZE} ||
      {
        echo "Error while tokenizing corpus!"
        exit 1
      }
  done
done

printf "\n\nEvaluating tokenizers...\n"
for ALGORITHM in "${ALGORITHM_LIST[@]}"; do
  for VOCAB_SIZE in "${VOCAB_SIZE_LIST[@]}"; do
    ./zipfer.sh -a ${ALGORITHM} -s ${VOCAB_SIZE} ||
      {
        echo "Error while evaluating tokenizers!"
        exit 1
      }
  done
done

printf "\n\nDone!\n"
