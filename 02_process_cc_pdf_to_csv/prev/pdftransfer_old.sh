#!/bin/bash

#----------------------------------
# Account Information

#SBATCH --account=pi-colonnelli

#------------------------------
# Resources requested

#SBATCH --partition=standard
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=32G
#SBATCH --cores-per-socket=2
#SBATCH --time=0-10:00:00

#---------------------
# Job specific name

#SBATCH --job-name=calltransfer

#-----------------------
# useful variables

echo "Job ID: $SLURM_JOB_ID"
echo "Job User: $SLURM_JOB_USER"
echo "Num Cores: $SLURM_JOB_CPUS_PER_NODE"

#------------------------
# change directory

cd "/project/kh_mercury_1/ConfCall20201024-20210405/CallScripts"

#--------------------------
# for every pdf in the file, use pdftotext to tranfer to text files

for file_name in *.pdf
do
	pdftotext -layout $file_name
done

#--------------------------

