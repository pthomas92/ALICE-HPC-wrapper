#!/bin/bash -l
#$ -l h_rt=48:00:00
#$ -l mem=10G
#$ -N test_ALICE
#$ -pe smp 10
#$ -t 1-196
#$ -wd /home/ucbtpt0/Scratch/output/jobscript_output

echo "Running on host: $(hostname)"
echo "Working directory is: $(pwd)"
echo "TMPDIR is: $TMPDIR"

# Parse parameter file to get variables.
paramfile="$HOME/Scratch/array-params-complete.txt"
number=$SGE_TASK_ID

index=$(sed -n "${number}p" "$paramfile" | awk '{print $1}')
rep_folder=$(sed -n "${number}p" "$paramfile" | awk '{print $2}' | sed "s|^\$HOME|$HOME|")
donor_folder=$(sed -n "${number}p" "$paramfile" | awk '{print $3}' | sed "s|^\$HOME|$HOME|")

echo "rep_folder is: $rep_folder"
echo "donor_folder is: $donor_folder"
echo "index is: $index"

cd "$TMPDIR"

echo "Starting job: $JOB_NAME ($JOB_ID) task $SGE_TASK_ID at $(date) on node $(hostname)" >> "$HOME/Scratch/output/job_start_${SGE_TASK_ID}.log"

# Load R and set number of threads
module -f unload compilers mpi gcc-libs
module load r/recommended
export OMP_NUM_THREADS=10

echo "Executing Rscript..."

Rscript /home/$USER/Scratch/runALICE-Myriad_single-Run_array.R "$rep_folder" "$donor_folder" > runALICE.out
STATUS=$?

echo "Finished Rscript!"

tar zcvf "$HOME/Scratch/output/${JOB_NAME}_${JOB_ID}_${SGE_TASK_ID}.tgz" ./*

if [ $STATUS -eq 0 ]; then
    echo -e "Job: $JOB_NAME\tID: $JOB_ID\tTask: $SGE_TASK_ID\tStatus: SUCCESS\tCompleted at: $(date)" >> "$HOME/Scratch/output/job_end_${SGE_TASK_ID}.log"
else
    echo -e "Job: $JOB_NAME\tID: $JOB_ID\tTask: $SGE_TASK_ID\tStatus: FAILURE (exit code $STATUS)\tCompleted at: $(date)" >> "$HOME/Scratch/output/job_end_${SGE_TASK_ID}.log"
fi

