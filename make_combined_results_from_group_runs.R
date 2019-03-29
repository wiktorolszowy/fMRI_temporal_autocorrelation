

###############################################################################################
####   Combining results from group analyses.
####   Written by:  Wiktor Olszowy, University of Cambridge
####   Contact:     olszowyw@gmail.com
####   Created:     August 2018
###############################################################################################


library(stringr)       #-for str_replace_all
library(AnalyzeFMRI)
library(R.matlab)
library(parallel)
library(ggplot2)


path_manage        = readLines("path_manage.txt")
path_scratch       = readLines("path_scratch.txt")
studies_parameters = read.table(paste0(path_manage, "/studies_parameters.txt"), sep=";", header=T)
group_types        = c("random", "mixed")
packages           = c("AFNI", "FSL", "SPM", "SPM_FAST")
studies            = studies_parameters$study
smoothing          = 8
exper_designs      = c(paste0("boxcar", seq(10, 40, by=2)), "event1", "event2")
no_subjects        = 20 #-group analyses were run only for the first 20 subjects
results            = array(NA, dim=c(length(group_types), length(packages), length(studies), length(exper_designs)))
coef1_average      = array(NA, dim=c(length(group_types), length(packages), length(studies), length(exper_designs), no_subjects))
se_average         = array(NA, dim=c(length(group_types), length(packages), length(studies), length(exper_designs), no_subjects))

studies_labels = rep("", length(studies))
for (study_id in 1:length(studies)) {
   study       = studies[study_id]
   study_label = str_replace_all(study, "_", " ")
   study_label = str_replace_all(study_label, "1400", "TR=1.4s")
   study_label = str_replace_all(study_label, "645",  "TR=0.645s")
   study_label = str_replace_all(study_label, " release 3",  "")
   study_label = str_replace_all(study_label, "FCP Beijing",              "FCP Beijing TR=2s")
   study_label = str_replace_all(study_label, "FCP Cambridge",            "FCP Cambridge TR=3s")
   study_label = str_replace_all(study_label, "BMMR checkerboard",        "BMMR checkerboard TR=3s")
   study_label = str_replace_all(study_label, "CRIC RS",                  "CRIC RS TR=2s")
   study_label = str_replace_all(study_label, "CRIC checkerboard",        "CRIC checkerboard TR=2s")
   study_label = str_replace_all(study_label, "simulated using neuRosim", "neuRosim simulated TR=2s")
   study_label = str_replace_all(study_label, "CamCAN sensorimotor",      "CamCAN sensorimotor TR=1.97s")
   study_label = str_replace_all(study_label, "TR", "(TR")
   study_label = str_replace_all(study_label, " RS", "")
   study_label = paste0(study_label, ")")
   if (study_id < 7) {
      study_label = paste0("REST: ", study_label)
   } else {
      study_label = paste0("TASK: ", study_label)
   }
   studies_labels[study_id] = study_label
}


for (group_type_id in 1:length(group_types)) {

   group_type  = group_types[group_type_id]

   for (package_id in 1:length(packages)) {

      package  = packages[package_id]

      for (study_id in 1:length(studies)) {

         study = paste0(studies_parameters$study[study_id])
         abbr  = str_replace_all(paste0(studies_parameters$abbr [study_id]), pattern=" ", repl="")
         task  = str_replace_all(paste0(studies_parameters$task [study_id]), pattern=" ", repl="")

         for (exper_design_id in 1:length(exper_designs)) {

            exper_design = exper_designs[exper_design_id]

            #-for CamCAN data, only some experimental designs
            if (study=="CamCAN_sensorimotor" && exper_design!="boxcar10" && exper_design!="boxcar40" && exper_design!="event1" && exper_design!="event2")
               next
            end

            #-for other datasets, no 'event1' and no 'event2'
            if (study!="CamCAN_sensorimotor" && (exper_design=="event1" || exper_design=="event2"))
               next
            end

            path = paste0(path_scratch, "/analysis_output_", study, "/", package, "/smoothing_", smoothing, "/exper_design_", exper_design, "/HRF_gamma2_D")
            setwd(path)

            if (file.exists(paste0("group_analysis_", group_type, "_effects"))) {

               #-checking the number of voxels covered by significant clusters
               if (group_type=="random") {
                  indices          = readLines("group_analysis_random_effects/indices.txt")
                  if (file.size("group_analysis_random_effects/indices.txt")>1) {
                     no_sig_voxels = length(indices)
                  } else {
                     no_sig_voxels = 0
                  }
               } else {
                  cluster_sizes    = readLines("group_analysis_mixed_effects/cluster_sizes.txt")
                  last_line        = cluster_sizes[length(cluster_sizes)]
                  if (last_line=="#** NO CLUSTERS FOUND ***") {
                     no_sig_voxels = 0
                  } else {
                     no_sig_voxels = as.numeric(substr(last_line, 2, 7))
                  }
               }

               mask = f.read.nifti.volume(paste0("group_analysis_", group_type, "_effects/mask.nii"))

               if (no_sig_voxels>0) {
                  cat(str_pad(paste(group_type, "effects,"), 15, pad=" ", side="right"), str_pad(package, 9, pad=" ", side="right"), ",", str_pad(studies_labels[study_id], 38, pad=" ", side="right"), ",", str_pad(exper_design, 9, pad=" ", side="right"), ",", paste0(round(no_sig_voxels/sum(mask==1)*100, 2), "%"), " \n")
                  results[group_type_id, package_id, study_id, exper_design_id] = no_sig_voxels/sum(mask==1)
               } else {
                  results[group_type_id, package_id, study_id, exper_design_id] = 0
               }

               #-checking if the sample sizes are correct
               if (group_type=="random") {
                  SPM = readMat("group_analysis_random_effects/SPM.mat")
                  if (as.numeric(SPM$SPM[,,1]$nscan) != 20) {
                     cat(as.numeric(SPM$SPM[,,1]$nscan), "at", getwd(), "\n")
                  }
               } else {
                  system("3dinfo group_analysis_mixed_effects/group_output+orig > group_analysis_mixed_effects/3dinfo_output.txt", ignore.stderr=T)
                  info_output = readLines("group_analysis_mixed_effects/3dinfo_output.txt")
                  if (info_output[23]!="     statcode = fitt;  statpar = 19") {
                     cat(info_output[23], "at", getwd(), "\n")
                  }
               }
               
               #-checking averages of 'coef1_FSL_SPM_masked_MNI.nii' and 'tstat1_FSL_SPM_masked_MNI.nii' (via standard error), only for mixed effects analyses
               if (group_type=="mixed") {

                  #-using the parallel package for speed-up
                  res = mclapply(1:no_subjects, function(subject_id) {
                     
                     setwd(path)
                     subject       = paste0("sub-", abbr, strrep("0", 4-nchar(paste(subject_id))), subject_id)
                     if (!file.exists(paste0(subject, "/standardized_stats/coef1_FSL_SPM_masked_MNI.nii"))) {
                        cat(study, subject, "likely BMMR, where the omnibus contrast for SPM/FAST did not return any voxels in some rare runs \n")
                        cat(getwd(), subject, "\n")
                        return(c(NA, NA))
                     }
                     coef1         = f.read.nifti.volume(paste0(subject, "/standardized_stats/coef1_FSL_SPM_masked_MNI.nii"))
                     tstat1        = f.read.nifti.volume(paste0(subject, "/standardized_stats/tstat1_FSL_SPM_masked_MNI.nii"))
                     coef1[!mask]  = NA
                     tstat1[!mask] = NA
                     coef1[which(coef1==0)]   = NA
                     tstat1[which(tstat1==0)] = NA
                     #-standard error
                     se            = coef1/tstat1
                     return(c(mean(coef1, na.rm=T), mean(se, na.rm=T)))
                     
                  }, mc.cores=24)

                  coef1_average[group_type_id, package_id, study_id, exper_design_id, 1:no_subjects] = unlist(res)[seq(1, 2*no_subjects, by=2)]
                  se_average   [group_type_id, package_id, study_id, exper_design_id, 1:no_subjects] = unlist(res)[seq(2, 2*no_subjects, by=2)]
                  
               }

            } else {

               cat("sth weird at ", getwd(), "\n")

            }

         }

      }

   }

}

setwd(path_manage)
