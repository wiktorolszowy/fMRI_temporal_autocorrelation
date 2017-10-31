#!/bin/bash

###############################################################################################
####   AFNI analysis for 1 fMRI scan, for different combinations of options.
####   Written by:    Wiktor Olszowy, University of Cambridge
####   Contact:       wo222@cam.ac.uk
####   Created:       February-October 2017
####   Adapted from:  https://github.com/wanderine/ParametricMultisubjectfMRI/tree/master/AFNI
###############################################################################################


path_manage=`cat path_manage.txt`
path_scratch=`cat path_scratch.txt`
cd $path_manage
declare -a studies=$(awk -F';' '{ if (NR!=1) print $1 }' studies_parameters.txt)
declare -a   abbrs=$(awk -F';' '{ if (NR!=1) print $6 }' studies_parameters.txt)
declare -a   tasks=$(awk -F';' '{ if (NR!=1) print $7 }' studies_parameters.txt)
studies=($studies)
abbrs=($abbrs)
tasks=($tasks)
study=${studies[study_id-1]}
abbr=${abbrs[study_id-1]}
task=${tasks[study_id-1]}
no_zeros=`echo 4-${#subject_id} | bc`
if [ ${no_zeros} -ge 1 ]
then
   zeros="$(printf '0%.0s' $(seq 1 $no_zeros))"
else
   zeros=""
fi
printf "$1"'%.s' $(eval "echo {1.."$(($2))"}");
subject=sub-${abbr}$zeros${subject_id}
declare -a smoothings=(0 4 5 8)
declare -a exper_designs=("boxcar10" "boxcar12" "boxcar14" "boxcar16" "boxcar18" "boxcar20" "boxcar22" "boxcar24" "boxcar26" "boxcar28" "boxcar30" "boxcar32" "boxcar34" "boxcar36" "boxcar38" "boxcar40")
HRF_model=gamma2_D
freq_cutoff=same
path_data=${path_scratch}/scans_${study}
path_output=${path_scratch}/analysis_output_${study}/AFNI/freq_cutoffs_${freq_cutoff}

#-for regress_censor_motion 0.3 errors appear (particularly for CRIC patients!)
for ((smoothing_id=0; smoothing_id<${#smoothings[@]}; smoothing_id++)) {
   smoothing=${smoothings[smoothing_id]}
   #-for smoothing=0.0 errors appear, that is why 0.1 mm smoothing applied
   if [ ${smoothing} == 0 ]
   then
      zero_aux=1
   else
      zero_aux=0
   fi
   for ((exper_design_id=0; exper_design_id<${#exper_designs[@]}; exper_design_id++)) {
      exper_design=${exper_designs[exper_design_id]}
      #-stimulus duration in brackets needed for convolution
      HRF="SPMG2(${exper_design:6:2})"
      echo $study $subject $smoothing $exper_design $HRF_model
      cd ${path_output}/smoothing_${smoothing}/exper_design_${exper_design}/HRF_${HRF_model}
      
      afni_proc.py                                                                \
         -subj_id $subject                                                        \
         -script proc.$subject -scr_overwrite                                     \
         -tcat_remove_first_trs 0                                                 \
         -dsets ${path_data}/${subject}_${task}_bold.nii                          \
         -volreg_align_to third                                                   \
         -blur_size ${smoothing}.${zero_aux}                                      \
         -regress_stim_types AM1                                                  \
         -regress_stim_times                                                      \
            ${path_manage}/experimental_designs/AFNI_${study}_${exper_design}.txt \
         -regress_stim_labels activation_stimulus                                 \
         -regress_basis ${HRF}                                                    \
         -regress_opts_3dD                                                        \
            -jobs 1                                                               \
            -gltsym 'SYM: activation_stimulus'                                    \
            -glt_label 1 activity                                                 \
         -regress_make_ideal_sum sum_ideal.1D                                     \
         -regress_run_clustsim no 	                                              \
         -regress_est_blur_epits                                                  \
         -regress_est_blur_errts                                                  \
         -regress_reml_exec                                                       \
         -regress_opts_reml -Rwherr whitened_errts.${subject}_REML
      
      #-run the AFNI analysis
      tcsh -xef proc.${subject} |& tee  output.proc.${subject}
      
      mv ${subject}.results ${subject}
      mv proc.${subject} ${subject}/proc.${subject}
      mv output.proc.${subject} ${subject}/output.proc.${subject}
      
   }
}
