
| Written by: | Wiktor Olszowy, Department of Clinical Neurosciences, University of Cambridge     |
| ----------- | --------------------------------------------------------------------------------- |
| When:       | September 2016 - March 2019                                                       |
| Purpose:    | Study "Accurate autocorrelation modeling substantially improves fMRI reliability" |
| Preprint:   | https://www.nature.com/articles/s41467-019-09230-w.pdf                            |
| Contact:    | olszowyw@gmail.com                                                                |

Repeat the analyses
==============

To repeat some/all of the analyses presented in the paper, or perform such analyses for other data/different options, the paths ('path_manage.txt' and 'path_scratch.txt') and the table 'studies_parameters.txt' have to be adjusted, the fMRI scans have to be downloaded and renamed following a BIDS influenced standard:
```
'sub-' + string(3-letter-dataset-abbr) + string(4-digit id going from 1 to the number of subjects in that dataset) + '_' + string(task) + '_bold.nii'
```
The dataset abbreviation and the task name can be taken from the table 'studies_parameters.txt'.
For example for dataset 'FCP_Beijing', the dataset abbreviation is 'FCB' and the task is resting state ('rest'), so the first scan should be called:
```
sub-FCB0001_rest_bold.nii
```
while the accompanying T1 weighted ('T1w') anatomical scan and the brain extracted 'T1w' scan should be called:
```
sub-FCB0001_T1w.nii
sub-FCB0001_T1w_brain.nii
```
Although the names of the scans follow the BIDS standard, the 'bold', 'T1w' and 'T1w_brain' scans for each study are in one folder together: 'scans_FCP_Beijing' for the example above.

FCP and NKI datasets are available to everyone after registration on the NITRC platform. CamCAN data is a free-access dataset too. BMMR and CRIC scans have not been made public yet.
The simulated scans can be made using the attached script 'simulate_4D.R'.

The order in which the scripts should be run:
```
matlab -r -nodesktop "run('make_folders.m'); exit"

R -e "source('make_experimental_designs.R')"
R -e "source('make_parallel_commands.R')"

part=1; sbatch --array=1-980 slurm_submit.array.hphi; sleep 60  #-for AFNI
part=2; sbatch --array=1-980 slurm_submit.array.hphi; sleep 60  #-for FSL
part=3; sbatch --array=1-980 slurm_submit.array.hphi; sleep 60  #-for SPM
part=4; sbatch --array=1-980 slurm_submit.array.hphi; sleep 60  #-for post-stats

matlab -r -nodesktop "run('make_power_spectra.m'); exit"
matlab -r -nodesktop "run('make_combined_results_from_single_runs.m'); exit"

R -e "source('make_group_analyses_mixed_effects.R')"

matlab -r -nodesktop "run('make_group_analyses_random_effects.m'); exit"

R -e "source('make_combined_results_from_group_runs.R')"

matlab -r -nodesktop "run('make_figures.m'); exit"
```

Software
==============

I used the following software:

- Debian 3.16.43
- AFNI 16.2.02
- FSL 5.0.10
- SPM12 (r7219)
- R 3.3.3
- MATLAB 2017b

R dependencies
--------------

For the R computations, I used the following packages (available from CRAN):

- AnalyzeFMRI
- neuRosim
- oro.nifti
- parallel
- reshape2
- R.matlab
- stringr
- tools

Repository contents
==============

- `combined_results`

  Folder where MATLAB arrays are kept with results.
   - `combined.mat`
   
     For each subject, for each study and for each combination of options, the number of significant voxels is given.
   - `combined_fraction.mat`
   
     For each subject, for each study and for each combination of options, the percentage of significant voxels is given.
   - `pos_fractions.mat`
   
     'combined_fraction.mat' computed across subjects for each study and for each combination of options: the average percentage of significant (positive) voxels.
   - `pos_mean_numbers.mat`
   
     'combined.mat' computed across subjects for each study and for each combination of options: the mean number of significant (positive) voxels.
   - `pos_rates.mat`
   
     'combined.mat' computed across subjects for each study and for each combination of options: the proportion of subjects with at least 1 significant (positive) voxel.
   - ...
- `experimental_designs`

  Folder where experimental designs are kept, for AFNI and FSL, for each study and for each design. For SPM, the experimental designs can be easily embedded in the SPM commands.

   - `CamCAN_sensorimotor`

      Folder where true experimental designs for CamCAN are kept.
      - ...
   - `AFNI_BMMR_checkerboard_boxcar10.txt`
   
     Experimental design used for AFNI analyses, BMMR_checkerboard subjects and boxcar design 10s off + 10s on.
   - ...
- `figures`

  Figures made by the MATLAB script 'make_figures.m'. Figures from the paper, including from the supplement, can be found here.
   - ...
- `FSL_FEAT_designs`
   - `design_gamma2_D.fsf`
   
     FSL design file needed to run post-preprocessing/GLM FEAT for the 'double gamma with temporal derivative' HRF model.
   - `design_preproc.fsf`
   
     FSL design file needed to run preprocessing FEAT: motion correction + smoothing + high pass filtering + registration to MNI space.
- `matlab_extra_functions`

  MATLAB auxiliary functions.
   - `legendflex`
   
     Kelly Kearney's MATLAB toolbox to make legends in figures.
     - ...
   - `corrclusth.m`
   - `max_extent.m`
   
     Thomas Nichols' functions used for the PNAS 2016 Eklund et al. study, needed for cluster inference in SPM.
   - `parsave.m`
   
     Auxiliary function to save within parfor.
   - `parsave2.m`
   
     Auxiliary function to save within parfor.
   - `print_to_svg_to_pdf.m`
   
     Function to print a MATLAB figure to '.svg' and then to '.pdf', cropping the 'pdf' (removing margins) and deleting the '.svg' file at the end.
- `parallel_commands`

  Folder where the commands run later using the 'job array' option in 'sbatch' are kept. Each command refers to one subject and to an analysis in AFNI, FSL or SPM.
   - `command_1_1.sh`
   
     Run AFNI analysis for 1st subject from 1st study. The first '1' does not refer to the first study. It refers to the first group of commands (second group is for FSL...). The second index goes through all the subjects in all the studies: 1...980.
   - ...
- `analysis_for_one_subject_AFNI.sh`

  Bash script for AFNI and for one subject, but for different smoothings and experimental_designs.
- `analysis_for_one_subject_FSL.R`

  R script for FSL and for one subject, but for different smoothings and experimental_designs.
- `analysis_for_one_subject_SPM.m`

  MATLAB script for SPM and for one subject, but for different smoothings and experimental_designs.
- `make_combined_results_from_single_runs.m`

  MATLAB script that makes arrays that are kept in the folder 'combined_results'.
- `make_experimental_designs.R`

  R script that makes experimental designs to be saved in the folder 'experimental_designs'.
- `make_figures.m`

  MATLAB script that makes figures for the paper.
- `make_folders.m`

  MATLAB script that makes folders where the AFNI/FSL/SPM analyses are going to be run in.
- `make_group_analyses_mixed_effects.R`

  R script that makes group analyses with AFNI's 3dMEMA after first level analyses with AFNI/FSL/SPM/FAST.
- `make_group_analyses_random_effects.m`

  MATLAB script that makes group analyses with SPM's summary statistic approach after first level analyses with AFNI/FSL/SPM/FAST.
- `make_parallel_commands.R`

  R script that makes commands that are later run using the 'job array' option in 'sbatch', which is the 'slurm' tool for running jobs on an HPC cluster. The commands are saved in 'parallel_commands'.
- `make_power_spectra.m`

  MATLAB script that computes the power spectra on the GLM residuals from AFNI, FSL and SPM.
- `path_manage.txt`

  Path specifying where the scripts/above mentioned folders are.
- `path_scratch.txt`

  Path specifying where the analysis results should be saved. Due to the large folder sizes, it should be some large scratch directory rather than the usually small home directory.
- `plot_power_spectra_of_GLM_residuals.m`

  MATLAB script that plots power spectra of GLM residuals in AFNI, FSL and SPM. Written for fMRI researchers who want to check if their analyses might be affected by imperfect pre-whitening.
- `multiple_comparison_correction_and_registration_to_MNI.R`

  R script that performs multiple comparison correction via FSL and that registers results to MNI space, also via FSL. It runs on statistic maps generated by AFNI, FSL and SPM.
- `simulate_4D.R`

  R script that makes 4-dimensional resting state fMRI data, used as one of the 11 datasets in the analyses/paper.
- `slurm_submit.array.hphi`

  Options for 'sbatch'.
- `studies_parameters.txt`

  Table with an overview of the 11 datasets employed. Parameters from this table are later read by AFNI/FSL/SPM.
