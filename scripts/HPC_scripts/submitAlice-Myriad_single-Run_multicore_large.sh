#!/bin/bash -l

# Example jobscript to run an OpenMP threaded R job across multiple cores on one node.
# This may be using the foreach packages foreach(...) %dopar% for example.

# Request ten minutes of wallclock time (format hours:minutes:seconds).
# Change this to suit your requirements.
#$ -l h_rt=20:0:0

# Request 1 gigabyte of RAM per core. Change this to suit your requirements.
#$ -l mem=10G

# Set the name of the job. You can change this if you wish.
#$ -N test_ALICE

# Select 12 threads. The number of threads here must equal the number of worker 
# processes in the registerDoMC call in your R program.
#$ -pe smp 10

# Set the working directory to somewhere in your scratch space.  This is
# necessary because the compute nodes cannot write to your $HOME
# NOTE: this directory must exist.
# Replace "<your_UCL_id>" with your UCL user ID
#$ -wd /home/ucbtpt0/Scratch/output/jobscript_output

echo "Running on host: $(hostname)"
echo "Working directory is: $(pwd)"
echo "rep_folder is: $rep_folder"
echo "donor_folder is: $donor_folder"
echo "tmpdir is: $TMPDIR"

# Your work must be done in $TMPDIR
cd $TMPDIR

echo "Starting job: $JOB_NAME ($JOB_ID) at $(date) on node $(hostname)" >> $HOME/Scratch/output/job_start.log

# Load the R module and run your R program
module -f unload compilers mpi gcc-libs
module load r/recommended

echo "Executing Rscript..."

Rscript /home/$USER/Scratch/runALICE-Myriad_single-Run.R "$rep_folder" "$donor_folder" > runALICE.out
STATUS=$?

echo "Finished Rscript!"

# Preferably, tar-up (archive) all output files to transfer them back 
# to your space. This will include the R_output file above.
tar zcvf $HOME/Scratch/output/$JOB_NAME.$JOB_ID.tgz $TMPDIR

if [ $STATUS -eq 0 ]; then
    echo -e "Job: $JOB_NAME\tID: $JOB_ID\tStatus: SUCCESS\tCompleted at: $(date)" >> $HOME/Scratch/output/job_end.log
else
    echo -e "Job: $JOB_NAME\tID: $JOB_ID\tStatus: FAILURE (exit code $STATUS)\tCompleted at: $(date)" >> $HOME/Scratch/output/job_end.log
fi
