
#-Wiktor Olszowy

path_manage  = readLines("path_manage.txt")
path_scratch = readLines("path_scratch.txt")
system("mkdir experimental_designs")
setwd(paste0(path_manage, "/experimental_designs"))

exper_design    = function(n, TR, random, off, on, randomOnsets, randomDurations, name) {
   if (random==F) {
      onsets    = seq(off,n*TR-on,by=off+on)
      durations = rep(on, length(onsets))
   } else {
      onsets    = round(randomOnsets[which(randomOnsets+10<n*TR)], digits=2)
      durations = round(randomDurations[1:length(onsets)],         digits=2)
   }
   stimulus_times = data.frame(onsets=onsets, durations=durations)
   FSL_output     = array(NA, dim=c(3,length(onsets)))
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

n                     = 1000
randomOnsets          = rep(NA, n)
randomDurations       = rep(NA, n)
set.seed(1)
randomOnsets[1]       = round(runif(1, 3, 6), digits=2)
randomDurations[1]    = round(runif(1, 1, 4), digits=2)
for (i in 2:n) {
   randomOnsets[i]    = round(randomOnsets[i-1] + randomDurations[i-1] + runif(1, 3, 6), digits=2)
   randomDurations[i] = round(runif(1, 1, 4), digits=2)
}
randomEvents = data.frame(randomOnsets=randomOnsets, randomDurations=randomDurations)
write(randomOnsets,    file="SPM_randomOnsets.txt",    sep="\n")
write(randomDurations, file="SPM_randomDurations.txt", sep="\n")

studies_parameters = read.table(paste0(path_manage, "/studies_parameters.txt"), sep=";", header=T)
studies            = paste0(studies_parameters$study)

for (study_id in 1:length(studies)) {
   study = studies[study_id]
   npts  = studies_parameters$npts[study_id]
   TR    = studies_parameters$TR[study_id]
   for (len in seq(10, 40, by=2)) {
      exper_design(n=npts, TR=TR, random=F, off=len, on=len, name=paste0(study, "_boxcar", len))
   }
   if (study=="CamCAN_sensorimotor") {
      #-0.1 chosen as the duration time for AFNI has to be positive
      exper_design(n=npts, TR=TR, random=T, randomOnsets=randomOnsets, randomDurations=rep(0.1, length(randomOnsets)), name=paste0(study, "_event2"))
   }
}

system("mkdir CamCAN_sensorimotor")
for (subject_id in 1:200) {
   setwd(paste0(path_scratch, "/scans_CamCAN_sensorimotor"))
   events_times = read.table(file=paste0("sub-CAS", strrep("0", 4-nchar(paste(subject_id))), subject_id, "_sensorimotor_events.tsv"), sep="\t", header=T)
   onsets       = events_times$onset
   setwd(paste0(path_manage, "/experimental_designs/CamCAN_sensorimotor"))
   #-AFNI
   for (i in 1:length(onsets)) {
      if (i==1) {
         AFNI_output = paste0(onsets[i], ":0.1") #-0.1 chosen as the duration time for AFNI has to be positive
      } else {
         AFNI_output = paste0(AFNI_output, " ", onsets[i], ":0.1") #-0.1 chosen as the duration time for AFNI has to be positive
      }
   }
   write(AFNI_output, file=paste0("AFNI_randomOnsets_", strrep("0", 4-nchar(paste(subject_id))), subject_id, ".txt"), ncolumns=3)
   #-FSL
   FSL_output     = array(NA, dim=c(3,length(onsets)))
   FSL_output[1,] = round(onsets, digits=2)
   FSL_output[2,] = rep(0.1,length(onsets))
   FSL_output[3,] = rep(1,  length(onsets))
   write(FSL_output, file=paste0("FSL_randomOnsets_", strrep("0", 4-nchar(paste(subject_id))), subject_id, ".txt"), ncolumns=3)
   #-SPM
   write(events_times$onset, file=paste0("SPM_randomOnsets_", strrep("0", 4-nchar(paste(subject_id))), subject_id, ".txt"), sep="\n")
}
setwd(path_manage)
