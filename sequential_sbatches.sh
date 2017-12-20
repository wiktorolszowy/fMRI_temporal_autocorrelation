#!/bin/bash

#! Wiktor Olszowy

set -o errexit

#-Folder where output and errors from running 'sbatch' will be saved.
mkdir out_err

#-AFNI
#part=1; export part; sbatch --array=1-780 slurm_submit.array.hphi; sleep 60

#-FSL
#part=2; export part; sbatch --array=1-780 slurm_submit.array.hphi; sleep 60

#-SPM
#part=3; export part; sbatch --array=1-780 slurm_submit.array.hphi; sleep 60

#-transform results to MNI space and do cluster inference, all through FSL
part=4; export part; sbatch --array=397-426 slurm_submit.array.hphi; sleep 60
