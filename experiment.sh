#! /bin/bash

ALGORITHM_LIST=(
  "unigram"
)

VOCAB_SIZE_LIST=(
  "50000"
)

TRAINED_DIR=./trained
ENCODED_DIR=./encoded
RESULTS_DIR=./results
INPUT=./data/minipile/data/minipile.txt

mkdir -p \
  ${TRAINED_DIR} \
  ${ENCODED_DIR} \
  ${RESULTS_DIR}

printf "Training tokenizers...\n"

for ALGORITHM in "${ALGORITHM_LIST[@]}"; do
  for VOCAB_SIZE in "${VOCAB_SIZE_LIST[@]}"; do

    # Skip the training step since the tokenizer is already trained
    [ -f "${TRAINED_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}".model ] &&
      [ -f "${TRAINED_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}".vocab ] &&
      continue

    ./tokenizer_train.sh -a ${ALGORITHM} -s ${VOCAB_SIZE} -i ${INPUT} -t ${TRAINED_DIR} ||
      {
        echo "Error while training tokenizers!"
        exit 1
      }
  done
done

printf "\n\nTokenizing the corpus...\n"
for ALGORITHM in "${ALGORITHM_LIST[@]}"; do
  for VOCAB_SIZE in "${VOCAB_SIZE_LIST[@]}"; do

    # Skip the encoding step since the tokenizer has already tokenized the corpus
    [ -f "${ENCODED_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}".txt ] && continue

    ./tokenizer_encode.sh -a ${ALGORITHM} -s ${VOCAB_SIZE} -i ${INPUT} -t ${TRAINED_DIR} -e ${ENCODED_DIR} ||
      {
        echo "Error while tokenizing the corpus!"
        exit 1
      }
  done
done

printf "\n\nEvaluating tokenizers...\n"
for ALGORITHM in "${ALGORITHM_LIST[@]}"; do
  for VOCAB_SIZE in "${VOCAB_SIZE_LIST[@]}"; do

    # Skip the evaluating step since the tokenizer is already evaluated
    [ -d "${RESULTS_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}" ] && continue

    ./zipfer.sh -a ${ALGORITHM} -s ${VOCAB_SIZE} -e ${ENCODED_DIR} -r ${RESULTS_DIR} ||
      {
        echo "Error while evaluating tokenizers!"
        exit 1
      }
  done
done

printf "\n\nDone!\n"
