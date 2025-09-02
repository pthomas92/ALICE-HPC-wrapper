#!/bin/bash

# Set base directories
BASE_DIR="$HOME/Scratch/output"
UNPACK_DIR="$BASE_DIR/unpacked"
RESULTS_DIR="$BASE_DIR/results"

# Make sure unpacked and results directories exist
mkdir -p "$UNPACK_DIR"
mkdir -p "$RESULTS_DIR"/archive/completed/logs
mkdir -p "$RESULTS_DIR"/archive/failed/logs

if [ $(ls $UNPACK_DIR | wc -l) != 0 ]; then
    echo "$UNPACK_DIR is not empty"
    exit 1
fi

# Loop through all matching .tgz files
for FILE in "$BASE_DIR"/ALICE_batch*.tgz; do
    # Extract filename (e.g., HVO_550630_D11.11366.tgz)
    FILENAME=$(basename "$FILE")

    # Parse donor, day, and run ID from filename
    if [[ "$FILENAME" =~ ALICE_batch_([0-9]+)_([0-9]+)\.tgz ]]; then
        SGE="${BASH_REMATCH[1]}"
        SUBTASK="${BASH_REMATCH[2]}"
    else
        echo "Skipping file with unrecognized format: $FILENAME"
        continue
    fi

    # Extract archive
    tar -xvzf "$FILE" -C "$UNPACK_DIR"

    SUBDIR=$(ls "$UNPACK_DIR")

    if [[ "$SUBDIR" =~ ([0-9]{6})-(D[0-9]{1,2}) ]]; then
        DONOR="${BASH_REMATCH[1]}"
        DAY="${BASH_REMATCH[2]}"
        
        NEW_FILE_NAME="$BASE_DIR/${DONOR}-${DAY}.tgz"

        mv "$FILE" "$NEW_FILE_NAME" # rename original zip file
        
        RES_FILE="${DONOR}_${DAY}_beta_ALICE-hits.csv"
        SRC_PATH="$UNPACK_DIR/${DONOR}-${DAY}/${RES_FILE}"
        DEST_PATH="${RESULTS_DIR}/${RES_FILE}"

        # Check if file exists
        if [ -f "$SRC_PATH" ]; then
            if [ -f "$DEST_PATH" ]; then
                echo "File already exists, skipping: $RES_FILE"
                mv $NEW_FILE_NAME $RESULTS_DIR/archive/completed
                mv $(ls $BASE_DIR/job_*_$SUBTASK.log) $RESULTS_DIR/archive/completed/logs
            else
                mv "$SRC_PATH" "$DEST_PATH"
                echo "Moved $RES_FILE to $RESULTS_DIR"
                mv "$NEW_FILE_NAME" "$RESULTS_DIR/archive/completed"
                mv $(ls $BASE_DIR/job_*_$SUBTASK.log) "$RESULTS_DIR/archive/completed/logs"
            fi
            rm -r $UNPACK_DIR/*
        else
            echo "Expected CSV file not found: $SRC_PATH"
            echo "> ${FILENAME} missing results. premature termination?" >> ${BASE_DIR}/csv_QC.txt
            mv "$NEW_FILE_NAME" "$RESULTS_DIR/archive/failed"
            mv $(ls $BASE_DIR/job_*_$SUBTASK.log) $RESULTS_DIR/archive/failed/logs

            # clean up unpack directory
            rm -r $UNPACK_DIR/*
            continue

        fi

    else
        echo "No csv results file found for: $FILENAME"
        echo "> ${FILENAME} failed ALICE_processing" >> ${BASE_DIR}/failed_ALICE.txt
        mv "$NEW_FILE_NAME" "$RESULTS_DIR/archive/failed"
        mv $(ls $BASE_DIR/job_*_$SUBTASK.log) $RESULTS_DIR/archive/failed/logs
        rm -r $UNPACK_DIR/*
        continue
    fi
done
