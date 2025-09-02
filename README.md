# HPC implementation of ALICE pipeline

### About
ALICE is a tool for estimating statistically enriched TCRs from single timepoint repertoire sequencing data by comparing the number of observed sequence neighbours to a generated distribution 
(source: https://doi.org/10.1371/journal.pbio.3000314, github: https://github.com/pogorely/ALICE/tree/master). On small datasets this algorithm can be run locally on a laptop, however for 
comparing longitudinal and/or large cohorts of data it was necessary for me to run this code using the UCL Myriad HPC cluster. This repo catalogues how to set up an HPC environment to run the 
ALICE algorithm on our HPC cluster. Due to the number of repertoires and timepoints that were processed it was submitted via an array job, using SGE.

### Software requirements
* HPC system using Linux
* An R installation (current version is 4.2.0)
	* Required R packages:
		* Biostrings >= 2.64.0
		* igraph >= v1.3.1
		* data.table >= 1.14.2
		* stringdist >= 0.9.8
* ALICE algorithm downloaded from github
	* I had to perform some fixes to the code to get it to run properly on our system (mostly ensuring correct filepath mapping), therefore I have provided my edited version. Users can 
download from github if they wish, but it may require the same tinkering.

### Repository setup
The pipeline was designed to run from $HOME/Scratch directory. This folder should contain the following directories:
* ALICE (the downloaded github repository)
* repertoires (folder containing the repertoires to be processed. We use files processed from the Chain Lab at UCL's decombinator pipeline doi: https://doi.org/10.1093/bioinformatics/btt004)
	* Regular expressions are set up to recognise files in the following format:
		* dcr_HVO_<6-digit-donor-id>_<timepoint>_1_beta.tsv.gz
			* dcr: decombinator
			* HVO_<6-digit-donor-id>: Healthy donor
			* timepoint: the day of PBMC sampling
	* completed: subdirectory that correctly processed files can be moved to
* logs: location that logfiles will be written to
* classification (folder containing text files describing infection states of the patient being processed)
* output (location that the scripts will write files to)
	* jobscript_output: location that STDOUT and STDERR files will be written to
	* results: location to extract the processed csv output files to
	* unpacked: location to extract the .tgz files to

### Example Run
I've provided 2 repertoires from the COVIDsortium study for analysis in this directory (Milighetti et al., DOI: 10.1016/j.isci.2023.106937). Perform tests using these files.

1. Clone this repository to your Scratch 

2. Copy the following files to the Scratch directory:
	* scripts/HPC_scripts/submitAlice-Myriad_single-Run_multicore_large_long_array.sh
		* Script that I used to submit the job to the scheduler

	* scripts/R_scripts/runALICE-Myriad_single-Run_array.R
		* Rscript that the above script calls

	* scripts/ALICE 
		* My edited version of the ALICE R code

	* data/repertoires
		* Folder containing donor repertoires (I called this CHIM_repertoires)

	* data/classification
		* Folder containing donor classifications (I called this CHIM_donors)

	* data/array-params-complete.txt
		* Information to pass to the scheduler to grab the correct reperoire and donor
		* For editing/creating a new file:
			Column 1: job number (not used by the script, but useful to see)
			Column 2: repertoire path
			Column 3: classification path

3. Copy the following files to the Scratch/output directory:
	* scripts/organisation_scripts/unpackresults.sh
	* scripts/organisation_scripts/movesource.sh
	* scripts/organisation_scripts/cleanupALICE.sh

	* For each, run chmod +x to enable them to be run
		* Check headers to ensure the filepaths are correct for your system

4. Submit the job to the scheduler:
```
qsub -t 1-2 submitAlice-Myriad_single-Run_multicore_large_long_array.sh
```
The -t flag here is used because the full script is designed to submit an array job across 196 repertoires. Use this to limit it to just the test repertoire.

5. When complete, navigate to the $HOME/Scratch/output directory and run:
```
./cleanupALICE.sh
```
To extract the results file to the 'results', move the source repertoire to the 'completed' and to move and rename the compressed output.
