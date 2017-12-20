
#-Wiktor Olszowy

path_manage        = readLines("path_manage.txt")
setwd(path_manage)
studies_parameters = read.table(paste0(path_manage, "/studies_parameters.txt"), sep=";", header=T)
subject_nos        = studies_parameters$n
lims               = seq(1, sum(subject_nos)*9+1, by=sum(subject_nos))
part               = 1

#-AFNI
id                 = 0
for (i in 1:length(subject_nos)) {
   for (j in 1:subject_nos[i]) {
      id = id + 1
      #if (id==lims[part+1]) {
      #   part = part + 1
      #}
      cat("export study_id=", i, "; export subject_id=", j, "; bash analysis_for_one_subject_AFNI.sh; \n", file=paste0("parallel_commands/command_", part, "_", id, ".sh"), sep="", append=F)
   }
}

#-FSL
id     = 0
part   = part+1
for (i in 1:length(subject_nos)) {
   for (j in 1:subject_nos[i]) {
      id = id + 1
      cat("R -e  'study_id=", i, "; subject_id=", j, "; freq_cutoff_id=2; source(\"analysis_for_one_subject_FSL.R\")' \n", file=paste0("parallel_commands/command_", part,   "_", id, ".sh"), sep="", append=F)
   }
}

#-SPM
id   = 0
part = part+1
for (i in 1:length(subject_nos)) {
   for (j in 1:subject_nos[i]) {
      id = id + 1
      cat("matlab -r -nodesktop \"study_id=", i, "; subject_id=", j, "; freq_cutoff_id=1; run('analysis_for_one_subject_SPM.m'); exit\" \n", file=paste0("parallel_commands/command_", part,   "_", id, ".sh"), sep="", append=F)
   }
}

#-statistic maps to MNI space and conduct multiple testing
id     = 0
part   = part+1
for (i in 1:length(subject_nos)) {
   for (j in 1:subject_nos[i]) {
      id = id + 1
      cat("R -e  'study_id=", i, "; subject_id=", j, "; freq_cutoff_id=2; source(\"register_to_MNI_and_do_multiple_testing.R\")' \n", file=paste0("parallel_commands/command_", part,   "_", id, ".sh"), sep="", append=F)
   }
}
