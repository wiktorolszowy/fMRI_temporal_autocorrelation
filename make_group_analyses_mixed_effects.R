

###############################################################################################
####   Aim: investigate if pre-whitening affects group level analyses when using a mixed
####   effects model (via AFNI).
####   Written by:    Wiktor Olszowy, University of Cambridge
####   Contact:       olszowyw@gmail.com
####   Created:       August 2018
####   Adapted from:  https://github.com/wanderine/ParametricMultisubjectfMRI/blob/master/AFNI/run_random_group_analyses_onesamplettest_MEMA_groupsize20.sh
###############################################################################################


library(stringr)       #-for str_replace_all
library(parallel)


path_manage        = readLines("path_manage.txt")
path_scratch       = readLines("path_scratch.txt")
studies_parameters = read.table(paste0(path_manage, "/studies_parameters.txt"), sep=";", header=T)
#-following Eklund ea 2016, I only consider 1-sample t-test, where the sample is of size 20
no_subjects        = 20
packages           = c("AFNI", "FSL", "SPM", "SPM_FAST")
smoothing          = 8
exper_designs      = c(paste0("boxcar", seq(10, 40, by=2)), "event1", "event2")
sm_pars            = array(NA, dim=c(length(packages), no_subjects, 3))


for (study_id in 1:length(studies)) {

   study           = paste0(studies_parameters$study[study_id])
   abbr            = str_replace_all(paste0(studies_parameters$abbr [study_id]), pattern=" ", repl="")
   task            = str_replace_all(paste0(studies_parameters$task [study_id]), pattern=" ", repl="")

   res = mclapply(1:length(exper_designs), function(exper_design_id) {

      exper_design = exper_designs[exper_design_id]

      #-for CamCAN data, only some experimental designs
      if (study=="CamCAN_sensorimotor" && exper_design!="boxcar10" && exper_design!="boxcar40" && exper_design!="event1" && exper_design!="event2")
         next
      end
      
      #-for other datasets, no 'event1' and no 'event2'
      if (study!="CamCAN_sensorimotor" && (exper_design=="event1" || exper_design=="event2"))
         next
      end

      for (package_id in 1:length(packages)) {

         package = packages[package_id]
         path    = paste0(path_scratch, "/analysis_output_", study, "/", package, "/smoothing_", smoothing, "/exper_design_", exper_design, "/HRF_gamma2_D/")
         setwd(path)

         system("mkdir group_analysis_mixed_effects")

         for (subject_id in 1:no_subjects) {

            subject      = paste0("sub-", abbr, strrep("0", 4-nchar(paste(subject_id))), subject_id)
            path_subject = paste0(path, subject)
            setwd(path_subject)
            
            if (!file.exists("standardized_stats")) {
               cat(study, subject, "likely BMMR, where the omnibus contrast for SPM/FAST did not return any voxels in some rare runs \n")
               next
            }
            
            #-deleting old files
            system("rm standardized_stats/coef1.nii",                        ignore.stderr=T)
            system("rm standardized_stats/coef1_FSL_SPM_masked.nii",         ignore.stderr=T)
            system("rm standardized_stats/coef1_FSL_SPM_masked.nii.gz",      ignore.stderr=T)
            system("rm standardized_stats/coef1_FSL_SPM_masked_MNI.nii",     ignore.stderr=T)
            system("rm standardized_stats/coef1_FSL_SPM_masked_MNI.nii.gz",  ignore.stderr=T)
            system("rm standardized_stats/tstat1.nii",                       ignore.stderr=T)
            system("rm standardized_stats/tstat1_FSL_SPM_masked_MNI.nii.gz", ignore.stderr=T)
            system("rm standardized_stats/tstat1_FSL_SPM_masked_MNI.nii",    ignore.stderr=T)
            system("rm standardized_stats/mask_MNI_across_packages.nii",     ignore.stderr=T)

            if (package=="AFNI") {

               system(paste0("3dAFNItoNIFTI -prefix ", path_subject, "/standardized_stats/coef1  ", path_subject, "/stats.", subject, "_REML+orig['activation_stimulus#0_Coef']"),  ignore.stderr=T)
               system(paste0("3dAFNItoNIFTI -prefix ", path_subject, "/standardized_stats/tstat1 ", path_subject, "/stats.", subject, "_REML+orig['activation_stimulus#0_Tstat']"), ignore.stderr=T)

            } else if (package=="FSL") {

               system("cp stats/pe1.nii.gz    standardized_stats/coef1.nii.gz")
               system("cp stats/tstat1.nii.gz standardized_stats/tstat1.nii.gz")

            } else if (package=="SPM" || package=="SPM_FAST") {
               
               #-replace NaNs (improper numbers) with 0
               system("fslmaths beta_0001.nii -nan standardized_stats/coef1")
               system("gunzip standardized_stats/coef1.nii.gz")
               system("cp standardized_stats/spmT_0001.nii standardized_stats/tstat1.nii")
               
            }

            setwd(paste0(path_subject, "/standardized_stats"))

            #-applying FSL and SPM masks
            system("fslmaths coef1  -mas mask coef1_FSL_SPM_masked")
            system("fslmaths tstat1 -mas mask tstat1_FSL_SPM_masked")

            #-registration to MNI space
            system("flirt -ref standard -in coef1_FSL_SPM_masked  -applyxfm -init example_func2standard.mat -out coef1_FSL_SPM_masked_MNI")
            system("flirt -ref standard -in tstat1_FSL_SPM_masked -applyxfm -init example_func2standard.mat -out tstat1_FSL_SPM_masked_MNI")

            #-uncompressing
            system("gunzip coef1_FSL_SPM_masked_MNI.nii.gz")
            system("gunzip tstat1_FSL_SPM_masked_MNI.nii.gz")

         }

      }

      #-masking 'coef1_FSL_SPM_masked_MNI.nii' the same way across AFNI/FSL/SPM/FAST
      for (subject_id in 1:no_subjects) {

         subject         = paste0("sub-", abbr, strrep("0", 4-nchar(paste(subject_id))), subject_id)
         path_to_AFNI    = paste0(path_scratch, "/analysis_output_", study, "/AFNI/smoothing_", smoothing, "/exper_design_", exper_design, "/HRF_gamma2_D/", subject, "/standardized_stats")
         #-saving 'mask_MNI_across_packages.nii' only under AFNI
         AFNI_mask_within_command = paste0("3dMean -prefix ", path_to_AFNI, "/mask_MNI_across_packages.nii -mask_inter")

         for (package_id in 1:length(packages)) {

            package       = packages[package_id]
            path          = paste0(path_scratch, "/analysis_output_", study, "/", package, "/smoothing_", smoothing, "/exper_design_", exper_design, "/HRF_gamma2_D/", subject, "/standardized_stats")
            path_to_coef1 = paste0(path, "/coef1_FSL_SPM_masked_MNI.nii")

            #-the words 'FSL' and 'SPM' appear multiple times
            if (!file.exists(paste0(str_replace_all(path_to_coef1, paste0("/", package, "/"), "/SPM/"))) ||
                !file.exists(paste0(str_replace_all(path_to_coef1, paste0("/", package, "/"), "/SPM_FAST/")))) {
               cat(study, subject, "likely BMMR, where the omnibus contrast for SPM/FAST did not return any voxels in some rare runs \n")
               next
            }

            AFNI_mask_within_command = paste0(AFNI_mask_within_command, " ", path_to_coef1)

            #-extracting smoothness parameters, needed later for 3dClustSim
            setwd(path)
            FWHMmm       = readLines("smoothness")
            FWHMmm       = FWHMmm[5]
            white_spaces = gregexpr(' ', FWHMmm)[[1]][1:3]
            #-smoothness in x-direction [mm]
            sm_pars[package_id, subject_id, 1] = as.numeric(substr(FWHMmm, white_spaces[1]+1, white_spaces[2]-1))
            #-smoothness in y-direction [mm]
            sm_pars[package_id, subject_id, 2] = as.numeric(substr(FWHMmm, white_spaces[2]+1, white_spaces[3]-1))
            #-smoothness in z-direction [mm]
            sm_pars[package_id, subject_id, 3] = as.numeric(substr(FWHMmm, white_spaces[3]+1, nchar(FWHMmm)))

         }

         #-not for the subjects without 'standardized_stats' -> rare BMMR subjects
         if (substr(AFNI_mask_within_command, nchar(AFNI_mask_within_command)-10, nchar(AFNI_mask_within_command))!="-mask_inter") {
            system(AFNI_mask_within_command)
            for (package_id in 1:length(packages)) {
               package      = packages[package_id]
               path_aux     = paste0(path_scratch, "/analysis_output_", study, "/", package, "/smoothing_", smoothing, "/exper_design_", exper_design, "/HRF_gamma2_D/", subject, "/standardized_stats")
               system(paste0("fslmaths ", path_aux, "/coef1_FSL_SPM_masked_MNI.nii -mas ", path_to_AFNI, "/mask_MNI_across_packages.nii ", path_aux, "/coef1_FSL_SPM_masked_MNI.nii"))
               system(paste0("rm ",       path_aux, "/coef1_FSL_SPM_masked_MNI.nii"))
               system(paste0("gunzip ",   path_aux, "/coef1_FSL_SPM_masked_MNI.nii.gz"))
            }
         }

      }

      for (package in packages) {

         path = paste0(path_scratch, "/analysis_output_", study, "/", package, "/smoothing_", smoothing, "/exper_design_", exper_design, "/HRF_gamma2_D/")

         AFNI_mask_command   = paste0('3dMean -prefix ', path, 'group_analysis_mixed_effects/mask.nii -mask_inter')
         AFNI_3dMEMA_command = paste0('3dMEMA -mask ',   path, 'group_analysis_mixed_effects/mask.nii -jobs 12 -prefix ', path, 'group_analysis_mixed_effects/group_output -set groupA ')

         for (subject_id in 1:no_subjects) {

            subject      = paste0("sub-", abbr, strrep("0", 4-nchar(paste(subject_id))), subject_id)
            path_subject = paste0(path, subject)

            if (!file.exists(paste0(str_replace_all(path_subject, paste0("/", package, "/"), "/SPM/"),      "/standardized_stats/coef1_FSL_SPM_masked_MNI.nii")) ||
                !file.exists(paste0(str_replace_all(path_subject, paste0("/", package, "/"), "/SPM_FAST/"), "/standardized_stats/coef1_FSL_SPM_masked_MNI.nii"))) {
               cat(study, subject, "likely BMMR, where the omnibus contrast for SPM/FAST did not return any voxels in some rare runs \n")
               next
            }

            AFNI_mask_command   = paste0(AFNI_mask_command, " ", path_subject, '/standardized_stats/coef1_FSL_SPM_masked_MNI.nii')
            AFNI_3dMEMA_command = paste0(AFNI_3dMEMA_command, ' \"', subject, '\" \"', path_subject, '/standardized_stats/coef1_FSL_SPM_masked_MNI.nii\" \"',
                                                                                       path_subject, '/standardized_stats/tstat1_FSL_SPM_masked_MNI.nii\"')

         }
         
         system(AFNI_mask_command)
         system(AFNI_3dMEMA_command)
         
         setwd(paste0(path, "group_analysis_mixed_effects"))

         #-run cluster simulation to get p-values for clusters
         system(paste("3dClustSim -mask mask.nii -fwhmxyz ", mean(sm_pars[package_id,,1], na.rm=T),
                                                             mean(sm_pars[package_id,,2], na.rm=T),
                                                             mean(sm_pars[package_id,,3], na.rm=T),
                                          "-athr 0.05 -pthr 0.001 -nodec > cluster_threshold.txt"))

         cluster_threshold        = readLines("cluster_threshold.txt")
         last_line                = cluster_threshold[length(cluster_threshold)]
         cluster_extent_threshold = as.numeric(substr(last_line, nchar(last_line)-6, nchar(last_line)))

         #-CDT = cluster defining threshold
         CDT                      = qt(1-0.001, no_subjects-1)

         #-print clusters to text file
         system(paste0("3dclust -1dindex 1 -1tindex 1 -1noneg -1thresh ", CDT, " -dxyz=1 1.01 ", cluster_extent_threshold, " group_output+orig > cluster_sizes.txt"))

         #-replace NaNs (improper numbers) in 'mask.nii' with 0, needed due to some communication problem between AFNI and R's AnalyzeFMRI
         system("fslmaths mask.nii -nan mask.nii.gz")
         system("rm mask.nii")
         system("gunzip mask.nii.gz")

      }

   }, mc.cores=4)

   setwd(path_manage)

}
