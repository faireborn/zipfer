#! /bin/bash

set -euo pipefail

ALGORITHM_LIST=(
  "unigram"
  "bpe"
  "word"
  "char"
)

VOCAB_SIZE_LIST=(
  "2000"
  "4000"
  "6000"
  "8000"
  "10000"
  "20000"
  "30000"
  "40000"
  "50000"
  "60000"
  "70000"
  "80000"
  "90000"
  "100000"
)

TRAINED_DIR=./experiment/experiment/trained
ENCODED_DIR=./experiment/experiment/encoded
RESULTS_DIR=./experiment/experiment/results
INPUT=./data/minipile/data/minipile.txt

mkdir -p \
  ${TRAINED_DIR} \
  ${ENCODED_DIR} \
  ${RESULTS_DIR}

printf "Training tokenizers...\n"

TRAINING_JOBS=()
for ALGORITHM in "${ALGORITHM_LIST[@]}"; do
  for VOCAB_SIZE in "${VOCAB_SIZE_LIST[@]}"; do

    # Skip the training step since the tokenizer is already trained
    [ -f "${TRAINED_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}".model ] &&
      [ -f "${TRAINED_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}".vocab ] &&
      continue

    TRAINING_JOBS+=("./tokenizer_train.sh -a ${ALGORITHM} -s ${VOCAB_SIZE} -i ${INPUT} -t ${TRAINED_DIR}")
  done
done

# start training jobs
printf "%s\n" "${TRAINING_JOBS[@]}" | xargs -P "$(nproc)" -I{} bash -c "{}"

printf "\n\nTokenizing the corpus...\n"

TOKENIZING_JOBS=()
for ALGORITHM in "${ALGORITHM_LIST[@]}"; do
  for VOCAB_SIZE in "${VOCAB_SIZE_LIST[@]}"; do

    # Skip the encoding step since the tokenizer has already tokenized the corpus
    [ -f "${ENCODED_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}".txt ] && continue

    TOKENIZING_JOBS+=("./tokenizer_encode.sh -a ${ALGORITHM} -s ${VOCAB_SIZE} -i ${INPUT} -t ${TRAINED_DIR} -e ${ENCODED_DIR}")
  done
done

# start tokenizing jobs
printf "%s\n" "${TOKENIZING_JOBS[@]}" | xargs -P "$(nproc)" -I{} bash -c "{}"

printf "\n\nEvaluating tokenizers...\n"

EVALUATING_JOBS=()
for ALGORITHM in "${ALGORITHM_LIST[@]}"; do
  for VOCAB_SIZE in "${VOCAB_SIZE_LIST[@]}"; do

    # Skip the evaluating step since the tokenizer is already evaluated
    [ -d "${RESULTS_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}" ] && continue

    EVALUATING_JOBS+=("./zipfer.sh -a ${ALGORITHM} -s ${VOCAB_SIZE} -t ${TRAINED_DIR} -e ${ENCODED_DIR} -r ${RESULTS_DIR}")
  done
done

# start evaluating jobs
printf "%s\n" "${EVALUATING_JOBS[@]}" | xargs -P "$(nproc)" -I{} bash -c "{}"

for ALGORITHM in "${ALGORITHM_LIST[@]}"; do
  for VOCAB_SIZE in "${VOCAB_SIZE_LIST[@]}"; do
    if [ ${VOCAB_SIZE} == ${VOCAB_SIZE_LIST[0]} ]; then
      HEADER=$(awk 'NR==1' "${RESULTS_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}"/result.tsv)
      printf "vocab_size\t${HEADER}\n" >"${RESULTS_DIR}"/"${ALGORITHM}".tsv
    fi
    RESULT=$(awk 'NR==2' "${RESULTS_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}"/result.tsv)
    printf "${VOCAB_SIZE}\t${RESULT}\n" >>"${RESULTS_DIR}"/"${ALGORITHM}".tsv
  done
done

gnuplot -e "results_dir='${RESULTS_DIR}'" ./plot.gp

printf "\n\nDone!\n"
