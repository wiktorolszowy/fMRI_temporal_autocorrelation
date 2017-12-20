

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   Calculating power spectra on GLM residuals from AFNI/FSL/SPM.
%%%%   Written by:    Wiktor Olszowy, University of Cambridge
%%%%   Contact:       wo222@cam.ac.uk
%%%%   Created:       December 2017
%%%%   Adapted from:  https://github.com/wanderine/ParametricSinglesubjectfMRI/blob/master/FSL/fsl_powerspectra.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


path_manage         = fgetl(fopen('path_manage.txt'));
path_scratch        = fgetl(fopen('path_scratch.txt'));
path_output         = [path_scratch '/analysis_output_'];
studies_parameters  = readtable([path_manage '/studies_parameters.txt']);
studies             = studies_parameters.study;
softwares           = cellstr(['AFNI'; 'FSL '; 'SPM ']);
smoothings          = [0 4 5 8];
exper_designs       = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40']);
p                   = parpool(24);
range_softwares     = 1:length(softwares);
range_studies       = 1:length(studies);
range_exper_designs = 1:length(exper_designs);
range_smoothings    = 1:length(smoothings);
HRF_model           = 'gamma2_D';
fft_n               = 512; %FFT will pad the voxel-wise time series to that length with trailing zeros (if no. of time points lower) or truncate to that length (if no. of time points higher)


cd(path_manage);
addpath(genpath([path_manage '/matlab_extra_functions']));
warning('off', 'MATLAB:mir_warning_maybe_uninitialized_temporary');


for software_id = range_softwares
   software = softwares{software_id};
   for smoothing_id = range_smoothings
      smoothing = smoothings(smoothing_id);
      for exper_design_id = range_exper_designs
         exper_design = exper_designs{exper_design_id};
         for study_id = range_studies
            study         = studies_parameters.study{study_id};
            abbr          = studies_parameters.abbr{study_id};
            task          = studies_parameters.task{study_id};
            no_subjects   = studies_parameters.n(study_id);
            disp([study ' ' software]);
            cd([path_output study '/' software '/freq_cutoffs_same/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model]);
            parfor subject_id = 1:no_subjects
               subject = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
               cd([path_output study '/' software '/freq_cutoffs_same/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject]);
               %-removing output of previous runs
               system('rm standardized_stats/res4d.nii');
               system('rm standardized_stats/power_spectra_one_subject.mat');
               %-https://sites.google.com/site/kittipat/mvpa-for-brain-fmri/convert_matlab_nifti
               if strcmp(software, 'AFNI')
                  %-transforming AFNI GLM residuals to nifti
                  system(['3dcalc -a whitened_errts.' subject '_REML+orig -expr "a" -prefix standardized_stats/res4d.nii']);
               elseif strcmp(software, 'FSL')
                  system('gunzip stats/res4d.nii.gz');
                  copyfile 'stats/res4d.nii' 'standardized_stats/res4d.nii';
               elseif strcmp(software, 'SPM')
                  res_all = dir('Res_*.nii');
                  res_all = {res_all.name};
                  res_all = strjoin(res_all);
                  system(['fslmerge -t standardized_stats/res4d ' res_all]);
                  system('gunzip standardized_stats/res4d.nii.gz');
               end
               res4d          = MRIread('standardized_stats/res4d.nii');
               system('gunzip standardized_stats/zstat1_FSL_SPM_masked.nii.gz');
               zstat1_masked  = MRIread('standardized_stats/zstat1_FSL_SPM_masked.nii');
               res4d          = res4d.vol;
               zstat1_masked  = zstat1_masked.vol;
               dims           = size(res4d);
               power_spectra_one_subject = zeros(fft_n, 1);
               for i1 = 1:dims(1)
                  for i2 = 1:dims(2)
                     for i3 = 1:dims(3)
                        if zstat1_masked(i1, i2, i3) ~= 0
                           ts = squeeze(res4d(i1, i2, i3, :));
                           if (std(ts) ~= 0)
                              %-make signal variance equal to 1
                              ts = ts/(std(ts) + eps);
                              %-compute the discrete Fourier transform (DFT)
                              DFT = fft(ts, fft_n);
                              power_spectra_one_subject = power_spectra_one_subject + ((abs(DFT)).^2)/min(dims(4), fft_n);
                           end
                        end
                     end
                  end
               end
               %-average power spectra over all brain voxels
               power_spectra_one_subject = power_spectra_one_subject / sum(zstat1_masked(:) ~= 0);
               %-trick to save within parfor
               parsave('standardized_stats/power_spectra_one_subject.mat', power_spectra_one_subject);
            end
            power_spectra = zeros(fft_n, 1);
            for subject_id = 1:no_subjects
               subject       = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
               cd(subject);
               load('standardized_stats/power_spectra_one_subject.mat');
               power_spectra = power_spectra + power_spectra_one_subject;
               cd ..
            end
            %-average power spectra over subjects
            power_spectra = power_spectra / no_subjects;
            save('power_spectra.mat', 'power_spectra');
         end
      end
   end
end
