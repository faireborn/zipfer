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
  -* | --*)
    echo "Unknown option $1"
    exit 1
    ;;
  esac
done

spm_encode \
  --model=./data/minipile/data/trained/"${ALGORITHM}"_"${VOCAB_SIZE}".model \
  --input=./data/minipile/data/minipile.txt \
  --output=./data/minipile/data/encoded/"${ALGORITHM}"_"${VOCAB_SIZE}".txt
