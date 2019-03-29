

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   Calculating power spectra on GLM residuals from AFNI/FSL/SPM.
%%%%   Written by:    Wiktor Olszowy, University of Cambridge
%%%%   Contact:       olszowyw@gmail.com
%%%%   Created:       December 2017 - August 2018
%%%%   Adapted from:  https://github.com/wanderine/ParametricSinglesubjectfMRI/blob/master/FSL/fsl_powerspectra.m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


path_manage         = fgetl(fopen('path_manage.txt'));
path_scratch        = fgetl(fopen('path_scratch.txt'));
path_output         = [path_scratch '/analysis_output_'];
studies_parameters  = readtable([path_manage '/studies_parameters.txt']);
studies             = studies_parameters.study;
packages            = cellstr(['AFNI    '; 'FSL     '; 'SPM     '; 'SPM_FAST']);
smoothings          = [0 4 5 8];
exper_designs       = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40'; 'event1  '; 'event2  ']);
p                   = parpool(12);
range_packages      = 1:length(packages);
range_studies       = 1:length(studies);
range_exper_designs = [1 2 4 6 16 17 18];
range_smoothings    = [2 4];
HRF_model           = 'gamma2_D';
fft_n               = 512; %FFT will pad the voxel-wise time series to that length with trailing zeros (if no. of time points lower) or truncate to that length (if no. of time points higher)


cd(path_manage);
addpath(genpath([path_manage '/matlab_extra_functions']));
warning('off', 'MATLAB:mir_warning_maybe_uninitialized_temporary');


for package_id      = range_packages

   package          = packages{package_id};

   for study_id     = range_studies

      study         = studies_parameters.study{study_id};
      abbr          = studies_parameters.abbr{study_id};
      task          = studies_parameters.task{study_id};
      no_subjects   = studies_parameters.n(study_id);

      for smoothing_id = range_smoothings

         smoothing     = smoothings(smoothing_id);

         %-for CamCAN data, only smoothing 8 mm
         if strcmp(study, 'CamCAN_sensorimotor') && smoothing ~= 8
            continue
         end

         for exper_design_id = range_exper_designs

            exper_design     = exper_designs{exper_design_id};

            %-for CamCAN data, only some experimental designs
            if strcmp(study, 'CamCAN_sensorimotor') && ~strcmp(exper_design, 'boxcar10') && ~strcmp(exper_design, 'boxcar40') && ~strcmp(exper_design, 'event1') && ~strcmp(exper_design, 'event2')
               continue
            end

            %-for other datasets, no 'event1' and no 'event2'
            if ~strcmp(study, 'CamCAN_sensorimotor') && (strcmp(exper_design, 'event1') || strcmp(exper_design, 'event2'))
               continue
            end

            disp([package ' ' study ' ' num2str(smoothing) ' ' exper_design]);
            path_subjects = [path_output study '/' package '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model];
            cd(path_subjects);

            system('mv power_spectra.mat power_spectra_old.mat');

            parfor subject_id = 1:no_subjects

               subject        = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];

               if exist([path_subjects '/' subject '/standardized_stats'], 'dir') ~= 7
                  continue
               end

               cd([path_subjects '/' subject '/standardized_stats']);

               %-removing output of previous runs
               if exist('power_spectra_one_subject.mat', 'file') == 2
                  system('rm power_spectra_one_subject.mat');
               end

               %-uncompressing, because niftiread has some rare/irreproducible numerical problems when reading nii.gz
               if exist('res4d_FSL_SPM_masked.nii.gz',   'file') == 2
                  if exist('res4d_FSL_SPM_masked.nii',   'file') == 2
                     system('mv res4d_FSL_SPM_masked.nii res4d_FSL_SPM_masked_old.nii');
                  end
                  system('gunzip res4d_FSL_SPM_masked.nii.gz');
               end
               if exist('zstat1_FSL_SPM_masked.nii.gz',  'file') == 2
                  if exist('zstat1_FSL_SPM_masked.nii',  'file') == 2
                     system('mv zstat1_FSL_SPM_masked.nii zstat1_FSL_SPM_masked_old.nii');
                  end
                  system('gunzip zstat1_FSL_SPM_masked.nii.gz');
               end

               res4d          = niftiread('res4d_FSL_SPM_masked.nii');
               zstat1_masked  = niftiread('zstat1_FSL_SPM_masked.nii');

               system('gzip res4d_FSL_SPM_masked.nii');
               system('gzip zstat1_FSL_SPM_masked.nii');

               dims              = size(res4d);
               power_spectra_one_subject = zeros(fft_n, 1);

               for i1 = 1:dims(1)

                  for i2 = 1:dims(2)

                     for i3 = 1:dims(3)

                        if zstat1_masked(i1, i2, i3) ~= 0

                           ts = squeeze(res4d(i1, i2, i3, :));

                           if (std(ts) ~= 0)

                              %-make signal variance equal to 1
                              ts  = ts/(std(ts) + eps);

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
               parsave('power_spectra_one_subject.mat', power_spectra_one_subject);

            end

            power_spectra  = zeros(fft_n, 1);

            %-number of subjects without full output/without power spectra (some rare BMMR runs, only SPM/FAST)
            no_wo_output   = 0;

            for subject_id = 1:no_subjects

               subject       = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];

               if exist([path_subjects '/' subject '/standardized_stats'], 'dir') ~= 7
                  disp(['little output, probably the omnibus contrast from SPM/FAST did not return any voxels for BMMR! subject ' subject]);
                  no_wo_output  = no_wo_output + 1;
                  continue
               end

               cd([path_subjects '/' subject '/standardized_stats']);
               load('power_spectra_one_subject.mat');
               power_spectra = power_spectra + power_spectra_one_subject;

            end

            cd(path_subjects);

            %-average power spectra over subjects
            power_spectra = power_spectra / (no_subjects-no_wo_output);

            save('power_spectra.mat', 'power_spectra');

         end

      end

   end

end

cd(path_manage)
