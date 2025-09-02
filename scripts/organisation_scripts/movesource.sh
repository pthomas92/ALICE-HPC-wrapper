#!/bin/bash

# Set paths
RESULTS_DIR="$HOME/Scratch/output/results"
SOURCE_DIR="$HOME/Scratch/CHIM_repertoires"
COMPLETED_DIR="$SOURCE_DIR/completed"

# Ensure completed folder exists
mkdir -p "$COMPLETED_DIR"

# Loop through all matching .tgz files
for RESULT_FILE in "$RESULTS_DIR"/*ALICE-hits.csv; do
    BASENAME=$(basename "$RESULT_FILE")
    if [[ $BASENAME =~ ^([0-9]{6})_D([0-9]{1,2})_([a-zA-Z]+)_ALICE-hits\.csv$ ]]; then
        DONOR="${BASH_REMATCH[1]}"
        DAY="${BASH_REMATCH[2]}"
        CHAIN="${BASH_REMATCH[3]}"
    else
        echo "Skipping unrecognized file format: $BASENAME"
        continue
    fi

    # Map day to source naming
    case "$DAY" in
        0) DAY_SRC="pre" ;;
        7) DAY_SRC="day7" ;;
        14) DAY_SRC="day14" ;;
        *) DAY_SRC="D${DAY}" ;;
    esac

    SOURCE_FILE="dcr_HVO_${DONOR}_${DAY_SRC}_1_$CHAIN.tsv.gz"
    SOURCE_PATH="$SOURCE_DIR/$SOURCE_FILE"

    # Check if source file exists
    if [[ -f "$SOURCE_PATH" ]]; then
        echo "Source found for $BASENAME → moving to completed/"
        mv "$SOURCE_PATH" "$COMPLETED_DIR/"
    else
        echo "No matching source for $BASENAME"
    fi
done

