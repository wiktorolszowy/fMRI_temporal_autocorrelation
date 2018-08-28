

###############################################################################################
####   FSL analysis for 1 fMRI scan, for different combinations of options.
####   Written by:    Wiktor Olszowy, University of Cambridge
####   Contact:       wo222@cam.ac.uk
####   Created:       September 2016 - August 2018
###############################################################################################


library(reshape2)
library(tools)
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

      path_output = paste0(path_output_top, "/FSL/smoothing_", smoothing)
      path_output_exper_design = paste0(path_output, "/exper_design_", exper_design)

      if (exper_design==exper_designs[1]) {

         setwd(path_output_exper_design)

         #-copy the FSL 'preproc' design file
         system(paste0("cp ", path_manage, "/FSL_FEAT_designs/design_preproc.fsf ", path_output_exper_design, "/preproc_feats_designs/design_", subject, ".fsf"))
         setwd(paste0(path_output_exper_design, "/preproc_feats_designs"))

         #-change the scan
         def_scan        = "scan_replace"
         new_scan        = paste0(path_data, "/", subject, "_", task, "_bold")
         system(paste0("sed -i 's:'", def_scan, "':'", new_scan, "':g' ", "design_", subject, ".fsf"))

         #-change the subject name (needed for T1w_brain)
         def_T1w_brain   = "T1w_brain_replace"
         new_T1w_brain   = paste0(path_data, "/", subject)
         system(paste0("sed -i 's:'", def_T1w_brain, "':'", new_T1w_brain, "':g' ", "design_", subject, ".fsf"))

         #-change the number of time points and the total number of voxels
         def_npts        = "npts_replace"
         def_totalVoxels = "totalVoxels_replace"
         def_TR          = "TR_replace"

         #-taking the values for different studies from the studies_parameters.txt table
         new_npts        = paste0(studies_parameters$npts[study_id])
         new_totalVoxels = paste0(studies_parameters$totalVoxels[study_id])
         new_TR          = paste0(studies_parameters$TR[study_id])
         system(paste0("sed -i 's:'", def_npts,        "':'", new_npts,        "':g' ", "design_", subject, ".fsf"))
         system(paste0("sed -i 's:'", def_totalVoxels, "':'", new_totalVoxels, "':g' ", "design_", subject, ".fsf"))
         system(paste0("sed -i 's:'", def_TR,          "':'", new_TR,          "':g' ", "design_", subject, ".fsf"))

         #-change the output directory
         def_output = "output_replace"
         new_output = paste0(path_output_exper_design, "/preproc_feats/", subject, "_preproc")
         system(paste0("sed -i 's:'", def_output, "':'", new_output, "':g' ", "design_", subject, ".fsf"))

         #-change the smoothing
         def_smooth = "smoothing_replace"
         new_smooth = paste0(smoothing)
         system(paste0("sed -i 's:", def_smooth, ":", new_smooth, ":g' design_", subject, ".fsf"))

         #-registration to MNI space only for '4 mm' smoothing and for first exper_design
         if (smoothing==4 && exper_design==exper_designs[1]) {
            def_reg = "reg_replace_1"
            new_reg = "1"
            system(paste0("sed -i 's:'", def_reg,             "':'", new_reg,             "':g' ", "design_", subject, ".fsf"))
            def_reg2 = "reg_replace_2"
            new_reg2 = "1"
            system(paste0("sed -i 's:'", def_reg2,            "':'", new_reg2,            "':g' ", "design_", subject, ".fsf"))
            #-for 'BMMR_checkerboard', problems with BBR; later for each 'BMMR_checkerboard' subject, most accurate registration was chosen
            if (study=="BMMR_checkerboard") {
               def_df_reg2main_str = "BBR"
               new_df_reg2main_str = "9"
               system(paste0("sed -i 's:'", def_df_reg2main_str, "':'", new_df_reg2main_str, "':g' ", "design_", subject, ".fsf"))
            }
         } else {
            def_reg = "reg_replace_1"
            new_reg = "0"
            system(paste0("sed -i 's:'", def_reg,  "':'", new_reg,  "':g' ", "design_", subject, ".fsf"))
            def_reg2 = "reg_replace_2"
            new_reg2 = "0"
            system(paste0("sed -i 's:'", def_reg2, "':'", new_reg2, "':g' ", "design_", subject, ".fsf"))
         }
         
         #-change high-pass filter cutoff frequency
         def_cutoff = "cutoff_replace"
         new_cutoff = 100
         system(paste0("sed -i 's:'", def_cutoff, "':'", new_cutoff, "':g' ", "design_", subject, ".fsf"))

         #-change motion correction
         def_mc     = "mc_replace"
         def_mp     = "mp_replace"
         if (study=="BMMR_checkerboard") {
            new_mc  = 0
            new_mp  = 0
         } else {
            new_mc  = 1
            new_mp  = 1
         }
         system(paste0("sed -i 's:'", def_mc, "':'", new_mc, "':g' ", "design_", subject, ".fsf"))
         system(paste0("sed -i 's:'", def_mp, "':'", new_mp, "':g' ", "design_", subject, ".fsf"))
         
         #-FEAT 'preproc' analysis
         system(paste0("fsl5.0-feat design_", subject, ".fsf"))

      }

      path_output_exper_design_HRF = paste0(path_output_exper_design, "/HRF_", HRF_model)
      setwd(path_output_exper_design_HRF)

      #-copy the FEAT dir from the 'preproc' step
      system(paste0("cp -a ", path_output, "/exper_design_", exper_designs[1], "/preproc_feats/", subject, "_preproc.feat/ ", path_output_exper_design_HRF, "/"))

      #-change the name of the FEAT dir, to accommodate for the 'stats' step
      system(paste0("mv ", subject, "_preproc.feat ", subject, ".feat"))

      #-copy the FSL 'stats' design file
      system(paste0("cp ", path_manage, "/FSL_FEAT_designs/design_", HRF_model, ".fsf ", path_output_exper_design_HRF, "/design_", subject, ".fsf"))

      #-change the number of time points, the total number of voxels, TR, and cutoff frequency as above
      def_npts        = "npts_replace"
      def_totalVoxels = "totalVoxels_replace"
      def_TR          = "TR_replace"
      def_cutoff      = "cutoff_replace"
      new_npts        = paste0(studies_parameters$npts[study_id])
      new_totalVoxels = paste0(studies_parameters$totalVoxels[study_id])
      new_TR          = paste0(studies_parameters$TR[study_id])
      new_cutoff      = 100
      system(paste0("sed -i 's:'", def_npts,        "':'", new_npts,        "':g' ", "design_", subject, ".fsf"))
      system(paste0("sed -i 's:'", def_totalVoxels, "':'", new_totalVoxels, "':g' ", "design_", subject, ".fsf"))
      system(paste0("sed -i 's:'", def_TR,          "':'", new_TR,          "':g' ", "design_", subject, ".fsf"))
      system(paste0("sed -i 's:'", def_cutoff,      "':'", new_cutoff,      "':g' ", "design_", subject, ".fsf"))

      #-change the smoothing
      def_smooth = "smoothing_replace"
      new_smooth = paste0(smoothing)
      system(paste0("sed -i 's:", def_smooth, ":", new_smooth, ":g' design_", subject, ".fsf"))
      
      #-change the experimental design
      def_exper_design = "exper_design_replace"
      if (study=="CamCAN_sensorimotor" && exper_design=="event1") {
         new_exper_design = paste0(path_manage, "/experimental_designs/CamCAN_sensorimotor/FSL_randomOnsets_", strrep("0", 4-nchar(paste(subject_id))),       subject_id,       ".txt")
      } else {
         new_exper_design = paste0(path_manage, "/experimental_designs/FSL_", study, "_", exper_design, ".txt")
      }
      system(paste0("sed -i 's:", def_exper_design, ":", new_exper_design, ":g' design_", subject, ".fsf"))
      
      #-change the directory of the 'preproc' feat
      def_feat = "feat_preproc_location_replace"
      new_feat = paste0(path_output_top, "/FSL/smoothing_", smoothing, "/exper_design_", exper_design, "/HRF_", HRF_model, "/", subject, ".feat")
      system(paste0("sed -i 's:", def_feat, ":", new_feat, ":g' design_", subject, ".fsf"))

      #-change motion correction
      def_mc     = "mc_replace"
      def_mp     = "mp_replace"
      if (study=="BMMR_checkerboard") {
         new_mc  = 0
         new_mp  = 0
      } else {
         new_mc  = 1
         new_mp  = 1
      }
      system(paste0("sed -i 's:'", def_mc, "':'", new_mc, "':g' ", "design_", subject, ".fsf"))
      system(paste0("sed -i 's:'", def_mp, "':'", new_mp, "':g' ", "design_", subject, ".fsf"))

      #-FEAT 'stats' analysis
      system(paste0("fsl5.0-feat design_", subject, ".fsf"))
      log = scan(file=paste0(path_output_exper_design_HRF, "/", subject, ".feat/logs/feat1"), what="character", sep=NULL)
      if ("ERROR" %in% log) {
         cat("ERROR ENCOUNTERED", getwd(), "\n")
      }

      #-deleting '.feat' in the folder name
      system(paste0("mv ", subject, ".feat ", subject))

   }

}

setwd(path_manage)
