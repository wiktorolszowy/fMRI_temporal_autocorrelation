

###############################################################################################
####   Performing multiple comparison correction via FSL and registering results to MNI space
####   via FSL. For statistic maps generated in AFNI, FSL and SPM.
####   Written by:    Wiktor Olszowy, University of Cambridge
####   Contact:       wo222@cam.ac.uk
####   Created:       October 2017 - May 2018
###############################################################################################


library(reshape2)
library(tools)
library(R.matlab)
library(AnalyzeFMRI)
library(stringr)       #-for str_replace_all

path_manage        = readLines("path_manage.txt")
path_scratch       = readLines("path_scratch.txt")
studies_parameters = read.table(paste0(path_manage, "/studies_parameters.txt"), sep=";", header=T)
smoothings         = c(0, 4, 5, 8)
exper_designs      = c(paste0("boxcar", seq(10, 40, by=2)), "event1", "event2")
HRF_model          = "gamma2_D"
study              = paste0(studies_parameters$study[study_id])
abbr               = str_replace_all(paste0(studies_parameters$abbr [study_id]), pattern=" ", repl="")
task               = str_replace_all(paste0(studies_parameters$task [study_id]), pattern=" ", repl="")
subject            = paste0("sub-", abbr, strrep("0", 4-nchar(paste(subject_id))), subject_id)
path_data          = paste0(path_scratch, "/scans_", study)
path_output_top    = paste0(path_scratch, "/analysis_output_", study)
packages           = c("AFNI", "FSL", "SPM", "SPM_FAST")

#-disabling scientific notation, otherwise an error for a volume of exactly 300000...
options(scipen = 999)


for (package in packages) {

   for (smoothing in smoothings) {

      #-for CamCAN data, only smoothing 8 mm
      if (study=="CamCAN_sensorimotor" && smoothing != 8)
         next
      end

      for (exper_design in exper_designs) {

         #-for CamCAN data, only some experimental designs
         if (study=="CamCAN_sensorimotor" && exper_design!="boxcar10" && exper_design!="boxcar40" && exper_design!="event1" && exper_design!="event2")
            next
         end
         
         #-for other datasets, no 'event1' and no 'event2'
         if (study!="CamCAN_sensorimotor" && (exper_design=="event1" || exper_design=="event2"))
            next
         end

         path = paste0(path_output_top, "/", package, "/smoothing_", smoothing, "/exper_design_", exper_design, "/HRF_", HRF_model, "/", subject)
         setwd(path)

         system("mkdir standardized_stats")

         #-checking if the subject already analyzed, there should be at least 19 files in 'standardized_stats'
         if (length(list.files("standardized_stats"))>18) {
            #-likely the subject has already been fully analyzed
            next
         }

         cat(getwd(), "\n")

         if (package=="AFNI") {

            #-reading the degrees of freedom
            #-https://afni.nimh.nih.gov/afni/community/board/read.php?1,67177,67179#msg-67179
            #-ifs used to catch numerical problems with AFNI for 4 subjects in the "NKI RS TR=1.4s" dataset: ids 2&5 (no 'stats_REML'), 25&27 (no 'stats'):
            #-in each case (for the four subjects) problems only for one/two combination/s of smoothing and experimental design
            if (file.exists(paste0( "stats.", subject, "_REML+orig.BRIK"))==T) {
               system(paste0("3dinfo stats.", subject, "_REML+orig[2] > standardized_stats/3dinfo_output.txt"))
            } else if (file.exists(paste0("stats.", subject, "+orig.BRIK"))==T) {
               system(paste0("3dinfo       stats.", subject, "+orig[2]      > standardized_stats/3dinfo_output.txt"))
               cat(paste0("possible AFNI ERROR/problem (no 'stats_REML' file) at ", getwd(), "\n"))
            } else {
               cat(paste0("possible AFNI ERROR/problem (no 'stats' file) at ", getwd(), "\n"))
               next
            }
            info_output = readLines("standardized_stats/3dinfo_output.txt")
            line_20     = info_output[20]
            df          = substr(line_20, nchar(line_20)-3, nchar(line_20))
            if (substr(df, 1, 1)=="=") {
               df       = substr(df, 2, nchar(df))
            }
            df          = as.numeric(df)
            if (!is.numeric(df) || !(df>10) || !(df<10000)) {
               cat(paste0("FATAL ERROR related to df at ", getwd()))
            }

            #-transforming the t-statistic map to a z-statistic map
            #-https://afni.nimh.nih.gov/afni/community/board/read.php?1,156394,156428#msg-156428
            if (file.exists(paste0(    "stats.", subject, "_REML+orig.BRIK"))==T) {
               system(paste0("3dcalc -a stats.", subject, "_REML+orig'[2]' -expr 'fitt_t2z(a,", df, ")' -prefix standardized_stats/zstat1.nii"))
            } else {
               system(paste0("3dcalc -a stats.", subject,      "+orig'[2]' -expr 'fitt_t2z(a,", df, ")' -prefix standardized_stats/zstat1.nii"))
               cat(paste0("possible AFNI ERROR at ", getwd()))
            }

            #-transforming AFNI's GLM residuals to nifti
            #-https://sites.google.com/site/kittipat/mvpa-for-brain-fmri/convert_matlab_nifti
            #-ifs used to catch numerical problems with AFNI for 4 subjects in the "NKI RS TR=1.4s" dataset: ids 2&5 (no 'stats_REML'), 25&27 (no 'stats'):
            #-in each case (for the four subjects) problems only for one/two combination/s of smoothing and experimental design
            if (file.exists(paste0(    "whitened_errts.", subject, "_REML+orig.BRIK"))==T) {
               system(paste0('3dcalc -a whitened_errts.', subject, '_REML+orig -expr "a" -prefix standardized_stats/res4d.nii'));
            } else if (file.exists(paste0("errts.",       subject,      "+orig.BRIK"))==T) {
               system(paste0('3dcalc -a    errts.',       subject,      '+orig -expr "a" -prefix standardized_stats/res4d.nii'));
               cat(paste0("possible AFNI ERROR/problem (no 'whitened_errts' file) at ", getwd(), "\n"))
            } else {
               cat(paste0("possible AFNI ERROR/problem (no 'errts' file) at ", getwd(), "\n"))
               next
            }
            system("gzip standardized_stats/res4d.nii")

            #-applying FSL and SPM masks to non-masked 'zstat1' and 'res4d', so that for all packages the same brain mask used (one confounder less...)
            path_to_FSL = str_replace_all(path, "AFNI", "FSL")
            path_to_SPM = str_replace_all(path, "AFNI", "SPM")
            path = paste0(path, "/standardized_stats")
            setwd(path)
            system(paste0("fslmaths ", path, "/zstat1            -mas ", path_to_FSL, "/mask ", path, "/zstat1_FSL_masked"))
            system(paste0("fslmaths ", path, "/zstat1_FSL_masked -mas ", path_to_SPM, "/mask ", path, "/zstat1_FSL_SPM_masked"))
            system(paste0("fslmaths ", path, "/res4d             -mas ", path_to_FSL, "/mask ", path, "/res4d_FSL_masked"))
            system(paste0("fslmaths ", path, "/res4d_FSL_masked  -mas ", path_to_SPM, "/mask ", path, "/res4d_FSL_SPM_masked"))

         } else if (package=="FSL") {

            #-copying the z-statistic map
            if (length(which(list.files("stats")=="zstat1.nii.gz"))==1) {
               system("cp stats/zstat1.nii.gz standardized_stats/zstat1.nii.gz")
            } else {
               system("cp stats/zstat1.nii    standardized_stats/zstat1.nii")
            }

            #-reading the degrees of freedom
            df = scan("stats/dof", quiet=T)

            #-compressing and copying FSL's GLM residuals
            if (file.exists("stats/res4d.nii")==T) {
               system("gzip stats/res4d.nii")
            }
            system("cp stats/res4d.nii.gz standardized_stats/res4d.nii.gz")

            #-applying SPM mask to FSL-masked 'zstat1' and 'res4d', so that for all packages the same brain mask used (one confounder less...)
            path_to_SPM = str_replace_all(path, "FSL", "SPM")
            path        = paste0(path, "/standardized_stats")
            setwd(path)
            system(paste0("fslmaths ", path, "/zstat1 -mas ", path_to_SPM, "/mask ", path, "/zstat1_FSL_SPM_masked"))
            system(paste0("fslmaths ", path, "/res4d  -mas ", path_to_SPM, "/mask ", path, "/res4d_FSL_SPM_masked"))

         } else if (package=="SPM" || package=="SPM_FAST") {

            #-copying the t-statistic map
            system("cp spmT_0001.nii standardized_stats/spmT_0001.nii")

            #-reading the degrees of freedom
            #-https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind06&L=SPM&P=R186259&1=SPM&9=A&I=-3&J=on&X=03B60AE4F53D3D3C56&Y=WO222%40CAM.AC.UK&d=No+Match%3BMatch%3BMatches&z=4
            #-SPM.xX.erdf
            SPM = readMat("SPM.mat")
            df  = as.numeric(SPM$SPM[,,1]$xX[,,1]$erdf)

            #-transforming the t-statistic map to a z-statistic map
            #-https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;4c24cff5.0808
            system("fslmaths standardized_stats/spmT_0001.nii -mul 0 -add 1 standardized_stats/ones.nii")
            system(paste0("ttoz standardized_stats/ones standardized_stats/spmT_0001 ", df, " -zout standardized_stats/zstat1"))

            #-merging SPM's GLM residuals to one file
            res_all = sort(list.files()[which(substr(list.files(), 1, 4)=="Res_")])
            res_all = paste(res_all, collapse=" ")
            system(paste0("fslmerge -t standardized_stats/res4d ", res_all))

            #-applying FSL mask to SPM-masked 'zstat1' and 'res4d', so that for all packages the same brain mask used (one confounder less...)
            path_to_FSL = str_replace_all(path,        "SPM",   "FSL")
            path_to_FSL = str_replace_all(path_to_FSL, "_FAST", "")
            path        = paste0(path, "/standardized_stats")
            setwd(path)
            system(paste0("fslmaths ", path, "/zstat1 -mas ", path_to_FSL, "/mask ", path, "/zstat1_FSL_SPM_masked"))
            system(paste0("fslmaths ", path, "/res4d  -mas ", path_to_FSL, "/mask ", path, "/res4d_FSL_SPM_masked"))
            system("rm zstat1_FSL_SPM_masked.nii")
            system("rm mask.nii")

         }

         #-creating brain mask from 'zstat1_FSL_SPM_masked'
         system("fslmaths 'zstat1_FSL_SPM_masked'     -abs 'zstat1_FSL_SPM_masked_abs'")
         system("fslmaths 'zstat1_FSL_SPM_masked_abs' -bin 'mask'")

         #-estimating smoothness, needed to run the 'cluster' function in FSL (multiple comparison correction)
         #-https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=ind1710&L=FSL&D=0&X=CA0D5B74DD2B36BED5&Y=wo222%40cam.ac.uk&P=87052
         system(paste0("smoothest -r res4d_FSL_SPM_masked -d ", df, " -m mask > smoothness"))
         par = read.table("smoothness", header=F, sep=" ", nrows=3)
         system(paste0("cluster --in=zstat1_FSL_SPM_masked --oindex=cluster_index --thresh=3.09 --pthresh=0.05 --dlh=", par$V2[1], " --volume=", round(par$V2[2]), " > cluster.txt"))

         #-copying FSL MNI registration template and the corresponding transformation
         #-be careful with CamCAN data, as the standard pipeline considers only 8 mm smoothing for CamCAN!
         system(paste0("cp ", path_output_top, "/FSL/smoothing_4/exper_design_boxcar10/preproc_feats/", subject, "_preproc.feat/reg/standard.nii.gz standard.nii.gz"))
         system(paste0("cp ", path_output_top, "/FSL/smoothing_4/exper_design_boxcar10/preproc_feats/", subject, "_preproc.feat/reg/example_func2standard.mat example_func2standard.mat"))

         #-changing all names of clusters to 1, to avoid later problems with interpolation
         system("fslmaths 'cluster_index' -thr 0.5 -bin 'cluster_binary'")

         #-registering 'cluster_binary' and 'mask' to MNI space
         system("flirt -ref standard -in cluster_binary -applyxfm -init example_func2standard.mat -out cluster_binary_MNI")
         system("flirt -ref standard -in mask           -applyxfm -init example_func2standard.mat -out mask_MNI")

         #-unzipping, because 'f.read.nifti.volume' does not work with '.gz'
         system("gunzip mask.nii.gz                  -f")
         system("gunzip mask_MNI.nii.gz              -f")
         system("gunzip zstat1_FSL_SPM_masked.nii.gz -f")
         system("gunzip cluster_binary_MNI.nii.gz    -f")
         mask                  = f.read.nifti.volume("mask.nii")
         mask_MNI              = f.read.nifti.volume("mask_MNI.nii")
         zstat1_FSL_SPM_masked = f.read.nifti.volume("zstat1_FSL_SPM_masked.nii")
         cluster_binary_MNI    = f.read.nifti.volume("cluster_binary_MNI.nii")

         #-0.5 chosen to distinguish clusters/brain voxels (>=1) from non-clusters/non-brain voxels (=0)
         mask                  = mask     > 0.5
         mask                  = mask[,,,1]     * 1.0
         mask_MNI              = mask_MNI > 0.5
         mask_MNI              = mask_MNI[,,,1] * 1.0
         cluster_binary_MNI    = cluster_binary_MNI > 0.5
         cluster_binary_MNI    = cluster_binary_MNI[,,,1] * 1.0

         #-'cluster_binary_MNI.mat' is the ultimate output, 3-dim array showing where the significant clusters are
         writeMat("cluster_binary_MNI.mat", cluster_binary_MNI = cluster_binary_MNI)

         #-saving the numbers of brain mask voxels and of significant voxels
         write(sum(mask                  > 0.5),                       "no_of_mask_voxels")
         write(sum(mask_MNI              > 0.5),                       "no_of_MNI_mask_voxels")
         write(sum(cluster_binary_MNI    > 0.5),                       "no_of_MNI_sig_voxels")

         #-checking how many voxels in 'zstat1_FSL_SPM_masked' above 3.1
         zstat1_FSL_SPM_masked_thr = zstat1_FSL_SPM_masked     > 3.1
         zstat1_FSL_SPM_masked_thr = zstat1_FSL_SPM_masked_thr * 1.0

         #-saving the proportion of voxels with 'zstat1_FSL_SPM_masked' above 3.1
         write(sum(zstat1_FSL_SPM_masked_thr > 0.5) / sum(mask > 0.5), "prop_above_3_1")

         #-saving the size of 'res4d_FSL_SPM_masked'
         write(file.size("res4d_FSL_SPM_masked.nii.gz"), "res4d_FSL_SPM_masked_size")

         #-calculating and saving a 3D smoothness estimate (geometric mean of FWHMmm in x-, y- and z-directions)
         FWHMmm           = readLines("smoothness")
         FWHMmm           = FWHMmm[5]
         white_spaces     = gregexpr(' ', FWHMmm)[[1]][1:3]
         FWHMmm_x         = as.numeric(substr(FWHMmm, white_spaces[1]+1, white_spaces[2]-1))
         FWHMmm_y         = as.numeric(substr(FWHMmm, white_spaces[2]+1, white_spaces[3]-1))
         FWHMmm_z         = as.numeric(substr(FWHMmm, white_spaces[3]+1, nchar(FWHMmm)))
         FWHMmm_geom_mean = (FWHMmm_x*FWHMmm_y*FWHMmm_z)^(1/3)
         write(FWHMmm_geom_mean,                         "smoothness_3D")

         #-to make space
         if (file.exists("res4d_FSL_masked.nii.gz")==T) {
            system("rm res4d_FSL_masked.nii.gz")
         }
         if (smoothing==0 || smoothing==5) {
            system("rm res4d_FSL_SPM_masked.nii.gz")
         }
         system("rm res4d.nii.gz")

      }

   }

}

setwd(path_manage)
