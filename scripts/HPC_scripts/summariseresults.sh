#!/bin/bash

DONOR_PATH=$HOME/Scratch/CHIM_donors
RESULTS_PATH=$HOME/Scratch/output/results
SOURCE_PATH=$HOME/Scratch/CHIM_repertoires/completed

echo "donor,day,state,ALICE_hits,n_TCRs" > $RESULTS_PATH/ALICE-hit-count.csv

for ALICE_RESULT in $(ls $RESULTS_PATH/*ALICE-hits.csv); do

if [[ "$ALICE_RESULT" =~ ([0-9]{6})_(D[0-9]{1,2})_beta_ALICE-hits\.csv ]]; then
	DONOR="${BASH_REMATCH[1]}"
	DAY="${BASH_REMATCH[2]}"
    case "$DAY" in
    	D0)  DAY_SRC="pre" ;;
    	D7)  DAY_SRC="day7" ;;
    	D14) DAY_SRC="day14" ;;
    	*)   DAY_SRC="$DAY" ;; # fallback to whatever DAY is
    esac
	FILE_MATCH=$(grep -r "$DONOR" "$DONOR_PATH")
	if [[ $FILE_MATCH =~ .*/([a-zA-Z]+)_donors\.txt:$DONOR ]]; then
    	STATE="${BASH_REMATCH[1]}"
	fi
	FILE_PATH=$(ls $SOURCE_PATH/dcr_HVO_${DONOR}_${DAY_SRC}_*)
	TOTAL_SEQS=$(zcat "$FILE_PATH" | tail -n +2 | wc -l)
fi
echo "$DONOR,$DAY,$STATE,$(tail -n+2 $ALICE_RESULT | wc -l),$TOTAL_SEQS" >> $RESULTS_PATH/ALICE-hit-count.csv

done

