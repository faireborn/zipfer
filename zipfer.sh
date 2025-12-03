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
  -e | --encoded_dir)
    ENCODED_DIR="$2"
    shift
    shift
    ;;
  -r | --results_dir)
    RESULTS_DIR="$2"
    shift
    shift
    ;;
  -* | --*)
    echo "Unknown option $1"
    exit 1
    ;;
  esac
done

./zig-out/bin/zipfer \
  --target="${ENCODED_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}".txt \
  --output="${RESULTS_DIR}"/"${ALGORITHM}"_"${VOCAB_SIZE}"
