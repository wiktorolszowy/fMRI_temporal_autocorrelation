
#-Wiktor Olszowy

path_manage = readLines("path_manage.txt")
setwd(paste0(path_manage, "/experimental_designs"))

exper_design = function(n, TR, random, off, on, randomOnsets, randomDurations, name) {
   if (random==F) {
      onsets = seq(off,n*TR-on,by=off+on)
      durations = rep(on, length(onsets))
   } else {
      onsets = round(randomOnsets[which(randomOnsets+10<n*TR)])
      durations = round(randomDurations[1:length(onsets)])
   }
   stimulus_times = data.frame(onsets=onsets, durations=durations)
   FSL_output = array(NA, dim=c(3,length(onsets)))
   FSL_output[1,] = onsets
   FSL_output[2,] = durations
   FSL_output[3,] = rep(1,length(onsets))
   write(FSL_output, file=paste0("FSL_", name, ".txt"), ncolumns=3)
   for (i in 1:length(onsets)) {
      if (i==1) {
         AFNI_output = paste0(onsets[i], ":", durations[i])
      } else {
         AFNI_output = paste0(AFNI_output, " ", onsets[i], ":", durations[i])
      }
   }
   write(AFNI_output, file=paste0("AFNI_", name, ".txt"), ncolumns=3)
}

studies_parameters = read.table(paste0(path_manage, "/studies_parameters.txt"), sep=";", header=T)
studies = paste0(studies_parameters$study)

for (study_id in 1:length(studies)) {
   study = studies[study_id]
   npts = studies_parameters$npts[study_id]
   TR = studies_parameters$TR[study_id]
   for (len in seq(10, 40, by=2)) {
      exper_design(n=npts, TR=TR, random=F, off=len, on=len, name=paste0(study, "_boxcar", len))
   }
}

setwd(path_manage)
