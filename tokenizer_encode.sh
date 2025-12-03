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
  -e | --encoded_dir)
    ENCODED_DIR="$2"
    shift
    shift
    ;;
  -* | --*)
    echo "Unknown option $1"
    exit 1
    ;;
  esac
done

spm_encode \
  --model="${TRAINED_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}".model \
  --input="${INPUT}" \
  --output="${ENCODED_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}".txt \
  --output_format=id
