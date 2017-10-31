

###############################################################################################
####   Registering results to MNI space and doing FSL multiple testing. For AFNI, FSL and SPM.
####   Written by:    Wiktor Olszowy, University of Cambridge
####   Contact:       wo222@cam.ac.uk
####   Created:       October 2017
###############################################################################################


library(reshape2)
library(tools)
library(R.matlab)
library(AnalyzeFMRI)
library(stringr)       #-for str_replace_all

path_manage        = readLines("path_manage.txt")
path_scratch       = readLines("path_scratch.txt")
studies_parameters = read.table(paste0(path_manage, "/studies_parameters.txt"), sep=";", header=T)
smoothings         = c(4, 0, 5, 8)
freq_cutoffs       = c("different", "same")
exper_designs      = paste0("boxcar", seq(10, 40, by=2))
HRF_model          = "gamma2_D"
study              = paste0(studies_parameters$study[study_id])
abbr               = str_replace_all(paste0(studies_parameters$abbr [study_id]), pattern=" ", repl="")
task               = str_replace_all(paste0(studies_parameters$task [study_id]), pattern=" ", repl="")
subject            = paste0("sub-", abbr, strrep("0", 4-nchar(paste(subject_id))), subject_id)
freq_cutoff        = freq_cutoffs[freq_cutoff_id]
path_data          = paste0(path_scratch, "/scans_", study)
path_output_top    = paste0(path_scratch, "/analysis_output_", study)
softwares          = c("AFNI", "FSL", "SPM")

#-disabling scientific notation, otherwise an error for a volume of exactly 300000...
options(scipen = 999)


for (software in softwares) {
   if (software=="AFNI" && freq_cutoff=="different") {
      next
   }
   for (smoothing in smoothings) {
      for (exper_design in exper_designs) {
         path = paste0(path_output_top, "/", software, "/freq_cutoffs_", freq_cutoff, "/smoothing_", smoothing, "/exper_design_", exper_design, "/HRF_", HRF_model, "/", subject)
         if (software=="AFNI") {
            setwd(path)
            system("rm -r standardized_stats")
            system("mkdir standardized_stats")
            #-checking what are the degrees of freedom (df) of the t-statistic map
            #-https://afni.nimh.nih.gov/afni/community/board/read.php?1,67177,67179#msg-67179
            system(paste0("3dinfo stats.", subject, "_REML+orig[2] > standardized_stats/3dinfo_output.txt"))
            info_output = readLines("standardized_stats/3dinfo_output.txt")
            #-alternatively: singleString = paste(readLines("foo.txt"), collapse=" ")
            line_20 = info_output[20]
            df = substr(line_20, nchar(line_20)-3, nchar(line_20))
            if (substr(df, 1, 1)=="=") {
               df = substr(df, 2, nchar(df))
            }
            df = as.numeric(df)
            if (!is.numeric(df) || !(df>10) || !(df<10000)) {
               cat(paste0("FATAL ERROR related to df at ", getwd()))
            }
            #-transforming the t-statistic map to a z-statistic map
            #-https://afni.nimh.nih.gov/afni/community/board/read.php?1,156394,156428#msg-156428
            system(paste0("3dcalc -a stats.", subject, "_REML+orig'[2]' -expr 'fitt_t2z(a,", df, ")' -prefix standardized_stats/zstat1.nii"))
            #-applying FSL and SPM masks to non-masked 'zstat1', so that for all softwares the same brain mask used (one confounder less...)
            path_to_FSL = str_replace_all(path, "AFNI", "FSL")
            path_to_SPM = str_replace_all(path, "AFNI", "SPM")
            path = paste0(path, "/standardized_stats")
            setwd(path)
            system(paste0("fslmaths ", path, "/zstat1            -mas ", path_to_FSL, "/mask ", path, "/zstat1_FSL_masked"))
            system(paste0("fslmaths ", path, "/zstat1_FSL_masked -mas ", path_to_SPM, "/mask ", path, "/zstat1_FSL_SPM_masked"))
         } else if (software=="FSL") {
            setwd(path)
            system("rm -r standardized_stats")
            system("mkdir standardized_stats")
            if (length(which(list.files("stats")=="zstat1.nii.gz"))==1) {
               system("cp stats/zstat1.nii.gz standardized_stats/zstat1.nii.gz")
            } else {
               system("cp stats/zstat1.nii    standardized_stats/zstat1.nii")
            }
            path_to_SPM = str_replace_all(path, "FSL", "SPM")
            path = paste0(path, "/standardized_stats")
            setwd(path)
            #-applying SPM mask to FSL-masked 'zstat1', so that for all softwares the same brain mask used (one confounder less...)
            system(paste0("fslmaths ", path, "/zstat1 -mas ", path_to_SPM, "/mask ", path, "/zstat1_FSL_SPM_masked"))
         } else if (software=="SPM") {
            setwd(path)
            system("rm -r standardized_stats")
            system("mkdir standardized_stats")
            system("cp spmT_0001.nii standardized_stats/spmT_0001.nii")
            #-checking what are the degrees of freedom (df)
            #-https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind06&L=SPM&P=R186259&1=SPM&9=A&I=-3&J=on&X=03B60AE4F53D3D3C56&Y=WO222%40CAM.AC.UK&d=No+Match%3BMatch%3BMatches&z=4
            #-SPM.xX.erdf
            SPM = readMat("SPM.mat")
            df = as.numeric(SPM$SPM[,,1]$xX[,,1]$erdf)
            path_to_FSL = str_replace_all(path, "SPM", "FSL")
            path = paste0(path, "/standardized_stats")
            setwd(path)
            #-transforming the t-statistic map to a z-statistic map
            #-https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;4c24cff5.0808
            system("fslmaths spmT_0001.nii -mul 0 -add 1 ones.nii")
            system(paste0("ttoz ones spmT_0001 ", df, " -zout zstat1"))
            #-applying FSL mask to SPM-masked 'zstat1', so that for all softwares the same brain mask used (one confounder less...)
            system(paste0("fslmaths ", path, "/zstat1 -mas ", path_to_FSL, "/mask ", path, "/zstat1_FSL_SPM_masked"))
         }
         #-copying FSL MNI registration template and the corresponding transformation
         system(paste0("cp ", path_output_top, "/FSL/freq_cutoffs_", freq_cutoff, "/smoothing_", smoothings[1], "/exper_design_", exper_designs[1], "/preproc_feats/", subject, "_preproc.feat/reg/standard.nii.gz standard.nii.gz"))
         system(paste0("cp ", path_output_top, "/FSL/freq_cutoffs_", freq_cutoff, "/smoothing_", smoothings[1], "/exper_design_", exper_designs[1], "/preproc_feats/", subject, "_preproc.feat/reg/example_func2standard.mat example_func2standard.mat"))
         #-registering 'zstat1_FSL_SPM_masked' to MNI space
         system("flirt -ref standard -in zstat1_FSL_SPM_masked -applyxfm -init example_func2standard.mat -out zstat1_FSL_SPM_masked_MNI")
         #-creating brain mask from 'zstat1_FSL_SPM_masked_MNI', slight differences between brain masks for FSL and SPM possible, only because of the interpolation
         system("fslmaths 'zstat1_FSL_SPM_masked_MNI'     -abs 'zstat1_FSL_SPM_masked_MNI_abs'")
         system("fslmaths 'zstat1_FSL_SPM_masked_MNI_abs' -bin 'mask_MNI'")
         #-estimating smoothness, needed to run the 'cluster' function in FSL (multiple testing)
         #-https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1710&L=FSL&D=0&X=CA0D5B74DD2B36BED5&Y=wo222%40cam.ac.uk&P=87052
         system("smoothest -z zstat1_FSL_SPM_masked_MNI -m mask_MNI > smoothness_MNI")
         par = read.table("smoothness_MNI", header=F, sep=" ", nrows=3)
         system(paste0("cluster --in=zstat1_FSL_SPM_masked_MNI --oindex=cluster_index_MNI --thresh=3.09 --pthresh=0.05 --dlh=", par$V2[1], " --volume=", round(par$V2[2]), " > cluster_MNI.txt"))
         #-unzipping, because 'f.read.nifti.volume' does not work with '.gz'
         system("gunzip cluster_index_MNI.nii.gz -f")
         pos_mask_MNI = f.read.nifti.volume("cluster_index_MNI.nii")
         #-0.5 chosen to distinguish clusters (>=1) from non-clusters (=0)
         pos_mask_MNI = pos_mask_MNI > 0.5
         pos_mask_MNI = pos_mask_MNI[,,,1] * 1.0
         #-'pos_mask_MNI.mat' is the ultimate output, 3-dim array showing where the significant voxels are
         writeMat("pos_mask_MNI.mat", pos_mask_MNI = pos_mask_MNI)
      }
   }
}
