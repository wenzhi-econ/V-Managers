#!/bin/bash

#SBATCH --account=pi-virginiaminni
#SBATCH --job-name=main_outcomes_eventstudies
#SBATCH --partition=highmem
#SBATCH --mem=96G
#SBATCH --time=1-12:00:00

# Print some useful variables
echo "Job ID: $SLURM_JOB_ID"
echo "Job User: $SLURM_JOB_USER"
echo "Num Cores: $SLURM_JOB_CPUS_PER_NODE"

# Load the necessary software modules
module load stata/18.0

# create a new scratch directory for this job
scratch_dir="/scratch/${SLURM_JOB_USER}/${SLURM_JOB_ID}"
mkdir -p $scratch_dir

# use scratch dir to store tmp files
export STATATMP=$scratch_dir

# run script
dofile='0002MasterExtensions.do'

srun stata-mp -b do $dofile


# remove scratch directory when done
rm -r $scratch_dir