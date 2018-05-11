
#-Wiktor Olszowy

#-simulate 4D fMRI scans similar to 'FCP_Beijing', which is resting-state data

library(neuRosim)
library(oro.nifti)
library(parallel)
library(AnalyzeFMRI)

setwd("/home/wo222/others/neuRosim")

FCP_Beijing_RS = readNIfTI("Beijing_sub98617.nii")
baseline       = apply(FCP_Beijing_RS, 1:3, mean)
abbr           = "SIM"

res = mclapply(1:100, function(sub_id) {

   #-the following ordering, taken from manual, is wrong!
   #-weights refer to 6 different noises: "white", "temporal", "spatial", "low-frequency", "physiological", "task-related"
   #-from code:
   #-n <- (w[1] * n.white + w[2] * n.temp + w[3] * n.low + w[4] * n.phys + w[5] * n.task + w[6] * n.spat)/sqrt(sum(w^2))
   A = simVOLfmri(dim=c(64,64,33), nscan=225, TR=2, noise="mixture", rho.temp=0.48,
      w=c(0.25, 0.50, 0, 0, 0, 0.25), SNR=10, base=baseline)
   #-so that later ordering is easy
   sub_id_4digit = paste0("00000000", sub_id)
   sub_id_4digit = substr(sub_id_4digit, nchar(sub_id_4digit)-3, nchar(sub_id_4digit))
   writeNIfTI(nifti(A, datatype=16, pixdim=c(0,3.1,3.1,3.6,2,1,1,1)), paste0("sub-", abbr, sub_id_4digit, "_rest_bold"))
   system(paste0("gunzip sub-", abbr, sub_id_4digit, "_rest_bold.nii.gz"))
   system(paste0("cp Beijing_sub98617_T1.nii sub-",       abbr, sub_id_4digit, "_T1w.nii"))
   system(paste0("cp Beijing_sub98617_T1_brain.nii sub-", abbr, sub_id_4digit, "_T1w_brain.nii"))

}, mc.cores=24)

A = f.read.nifti.volume("Beijing_sub98617.nii")
A = f.read.nifti.volume("sub-SIM0001_rest_bold.nii")
dim(A)
all_AR1 = c(0)
for (i in 20:25) {
   for (j in 20:25) {
      for (k in 10:14) {
         ts = A[i,j,k,]
         #cat(arima(ts, order=c(1,0,0))$coef[1], "\n")
         all_AR1 = c(all_AR1, arima(ts, order=c(1,0,0))$coef[1])
      }
   }
}
mean(all_AR1)
