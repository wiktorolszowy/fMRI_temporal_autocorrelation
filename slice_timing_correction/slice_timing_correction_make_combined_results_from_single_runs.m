

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   Combining results from single runs to 'mat' files. Necessary for making figures.
%%%%   This is an additional analysis investigating the impact of slice timing correction.
%%%%   It was performed only for the 'CRIC checkerboard' and 'CamCAN' datasets, only for
%%%%   smoothing of 8 mm and only for the true designs.
%%%%   Written by:  Wiktor Olszowy, University of Cambridge
%%%%   Contact:     wo222@cam.ac.uk
%%%%   Created:     July 2017 - August 2018
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
combined            = (-1)*ones(length(packages), length(studies), 200, length(smoothings), length(exper_designs));  %-200: the maximum number of subjects in a dataset
combined_fraction   = (-1)*ones(length(packages), length(studies), 200, length(smoothings), length(exper_designs));
combined_res4d_size = (-1)*ones(length(packages), length(studies), 200, length(smoothings), length(exper_designs));
combined_smoothness = (-1)*ones(length(packages), length(studies), 200, length(smoothings), length(exper_designs));
combined_prop_ab_31 = (-1)*ones(length(packages), length(studies), 200, length(smoothings), length(exper_designs));
dims                = size(combined);
pos_rates           = NaN(dims([1 2 4 5]));
pos_mean_numbers    = NaN(dims([1 2 4 5]));
pos_fractions       = NaN(dims([1 2 4 5]));
res4d_size          = NaN(dims([1 2 4 5]));
smoothness          = NaN(dims([1 2 4 5]));
prop_ab_31          = NaN(dims([1 2 4 5]));
range_packages      = 1:length(packages);
range_studies       = [10 11]; %1:length(studies);
range_exper_designs = [4  17]; %1:length(exper_designs);
range_smoothings    = 4;       %1:length(smoothings);
HRF_model           = 'gamma2_D';


cd(path_manage);
addpath(genpath([path_manage '/matlab_extra_functions']));
warning('off', 'MATLAB:mir_warning_maybe_uninitialized_temporary');


for package_id    = range_packages

   package        = packages{package_id};

   for study_id   = range_studies

      study       = studies_parameters.study{study_id};
      abbr        = studies_parameters.abbr{study_id};
      task        = studies_parameters.task{study_id};
      no_subjects = studies_parameters.n(study_id);
      disp([package ' ' study]);
      cd(path_manage);

      parfor subject_id = 1:no_subjects

         subject        = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
         combined_parfor            = (-1)*ones(length(smoothings), length(exper_designs));
         combined_fraction_parfor   = (-1)*ones(length(smoothings), length(exper_designs));
         combined_res4d_size_parfor = (-1)*ones(length(smoothings), length(exper_designs));
         combined_smoothness_parfor = (-1)*ones(length(smoothings), length(exper_designs));
         combined_prop_ab_31_parfor = (-1)*ones(length(smoothings), length(exper_designs));

         %-suppressing warnings about changes to variable names within the tables
         warning('off', 'MATLAB:table:ModifiedVarnames');

         for smoothing_id       = range_smoothings

            smoothing           = smoothings(smoothing_id);

            %-for CamCAN data, only smoothing 8 mm
            if strcmp(study, 'CamCAN_sensorimotor') && smoothing ~= 8
               continue
            end

            if strcmp(study, 'CRIC_checkerboard')
               exper_design_id  = 4;
            elseif strcmp(study, 'CamCAN_sensorimotor')
               exper_design_id  = 17;
            end
            exper_design        = exper_designs{exper_design_id};

            %-for CamCAN data, only some experimental designs
            if strcmp(study, 'CamCAN_sensorimotor') && ~strcmp(exper_design, 'boxcar10') && ~strcmp(exper_design, 'boxcar40') && ~strcmp(exper_design, 'event1') && ~strcmp(exper_design, 'event2')
               continue
            end

            %-for other datasets, no 'event1' and no 'event2'
            if ~strcmp(study, 'CamCAN_sensorimotor') && (strcmp(exper_design, 'event1') || strcmp(exper_design, 'event2'))
               continue
            end

            cd([path_output study '/' package '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '_slice_timing_correction']);

            if exist(subject, 'dir') == 7
               cd([subject '/standardized_stats']);
            else
               disp([pwd ' ' subject]);
            end

            if exist('no_of_MNI_sig_voxels', 'file') == 2

               no_of_MNI_sig_voxels                                         = fscanf(fopen('no_of_MNI_sig_voxels',      'r'), '%d');
               combined_parfor           (smoothing_id, exper_design_id)    = no_of_MNI_sig_voxels;
               no_of_MNI_mask_voxels                                        = fscanf(fopen('no_of_MNI_mask_voxels',     'r'), '%d');

               if no_of_MNI_mask_voxels > 0

                  combined_fraction_parfor(smoothing_id, exper_design_id) = no_of_MNI_sig_voxels/no_of_MNI_mask_voxels;

                  %-residuals in SPM saved with format 'FLOAT64' opposed to 'FLOAT32' in AFNI and FSL
                  if strcmp(package, 'SPM') || strcmp(package, 'SPM_FAST')
                     combined_res4d_size_parfor(smoothing_id, exper_design_id) = fscanf(fopen('res4d_FSL_SPM_masked_size', 'r'), '%d')/2;
                  else
                     combined_res4d_size_parfor(smoothing_id, exper_design_id) = fscanf(fopen('res4d_FSL_SPM_masked_size', 'r'), '%d');
                  end

                  combined_smoothness_parfor(smoothing_id, exper_design_id) = fscanf(fopen('smoothness_3D',             'r'), '%f');
                  combined_prop_ab_31_parfor(smoothing_id, exper_design_id) = fscanf(fopen('prop_above_3_1',            'r'), '%f');

               else

                  disp(pwd);

               end

            else

               disp(pwd);

            end

            %-https://uk.mathworks.com/matlabcentral/answers/124335-caught-std-exception-exception-message-is-message-catalog-matlab-builtins-was-not-loaded-from-th
            fclose all;

         end

         combined           (package_id, study_id, subject_id, :, :) = combined_parfor;
         combined_fraction  (package_id, study_id, subject_id, :, :) = combined_fraction_parfor;
         combined_res4d_size(package_id, study_id, subject_id, :, :) = combined_res4d_size_parfor;
         combined_smoothness(package_id, study_id, subject_id, :, :) = combined_smoothness_parfor;
         combined_prop_ab_31(package_id, study_id, subject_id, :, :) = combined_prop_ab_31_parfor;

      end

   end

end

for i1 = 1:dims(1)
   for i2 = 1:dims(2)
      for i4 = 1:dims(4)
         for i5 = 1:dims(5)

            over_sub            = combined           (i1, i2, :, i4, i5);
            over_sub_fractions  = combined_fraction  (i1, i2, :, i4, i5);
            over_sub_res4d_size = combined_res4d_size(i1, i2, :, i4, i5);
            over_sub_smoothness = combined_smoothness(i1, i2, :, i4, i5);
            over_sub_prop_ab_31 = combined_prop_ab_31(i1, i2, :, i4, i5);

            %-(-0.5) chosen for numerical reasons; in fact, we only want to distinguish >=0 from <0
            if sum(over_sub>-0.5) > 0
               pos_rates       (i1, i2,    i4, i5) =  sum(over_sub>0)/sum(over_sub>-0.5);
               %-sum(over_sub<-0.5) considered, as that many times the default (-1) is subtracted; (-1) appears in 'combined' for non-subjects
               pos_mean_numbers(i1, i2,    i4, i5) = (sum(over_sub)            + sum(over_sub<-0.5)) / sum(over_sub>-0.5);
               pos_fractions   (i1, i2,    i4, i5) = (sum(over_sub_fractions)  + sum(over_sub<-0.5)) / sum(over_sub>-0.5);
               res4d_size      (i1, i2,    i4, i5) = (sum(over_sub_res4d_size) + sum(over_sub<-0.5)) / sum(over_sub>-0.5);
               smoothness      (i1, i2,    i4, i5) = (sum(over_sub_smoothness) + sum(over_sub<-0.5)) / sum(over_sub>-0.5);
               prop_ab_31      (i1, i2,    i4, i5) = (sum(over_sub_prop_ab_31) + sum(over_sub<-0.5)) / sum(over_sub>-0.5);
            end

         end
      end
   end
end

cd(path_manage);
save('combined_results/combined',          'combined');
save('combined_results/combined_fraction', 'combined_fraction');
save('combined_results/pos_rates',         'pos_rates');
save('combined_results/pos_mean_numbers',  'pos_mean_numbers');
save('combined_results/pos_fractions',     'pos_fractions');
save('combined_results/res4d_size',        'res4d_size');
save('combined_results/smoothness',        'smoothness');
save('combined_results/prop_ab_31',        'prop_ab_31');
