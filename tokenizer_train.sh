#! /bin/bash

while [[ $# -gt 0 ]]; do
  case $1 in
  -a | --algorithm)
    ALGORITHM="$2"
    shift
    shift
    ;;
  -s | --size)
    VOCAB_SIZE="$2"
    shift
    shift
    ;;

  -i | --input)
    INPUT="$2"
    shift
    shift
    ;;
  -t | --trained_dir)
    TRAINED_DIR="$2"
    shift
    shift
    ;;

  -* | --*)
    echo "Unknown option $1"
    exit 1
    ;;
  esac
done

spm_train \
  --input=${INPUT} \
  --model_prefix="${TRAINED_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}" \
  --model_type="${ALGORITHM}" \
  --vocab_size="${VOCAB_SIZE}" \
  --input_sentence_size=2000000 \
  --shuffle_input_sentence=true
