#!/bin/bash

./unpackresults.sh || { echo "Unpack failed"; exit 1; }
./movesource.sh || { echo "Move results failed"; exit 1; }

