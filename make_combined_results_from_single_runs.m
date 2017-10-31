

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   Combining results from single runs to mat files. Necessary for making figures.
%%%%   Written by:  Wiktor Olszowy, University of Cambridge
%%%%   Contact:     wo222@cam.ac.uk
%%%%   Created:     July-October 2017
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


path_manage         = fgetl(fopen('path_manage.txt'));
path_scratch        = fgetl(fopen('path_scratch.txt'));
path_output         = [path_scratch '/analysis_output_'];
studies_parameters  = readtable([path_manage '/studies_parameters.txt']);
studies             = studies_parameters.study;
softwares           = cellstr(['AFNI'; 'FSL '; 'SPM ']);
freq_cutoffs        = cellstr(['different'; 'same     ']);
smoothings          = [0 4 5 8];
exper_designs       = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40']);
p                   = parpool(24);
combined            = (-1)*ones(length(softwares), length(freq_cutoffs), length(studies), 198, length(smoothings), length(exper_designs));
dims                = size(combined);
pos_rates           = NaN(dims([1 2 3 5 6]));
pos_mean_numbers    = NaN(dims([1 2 3 5 6]));
range_softwares     = 1:length(softwares);
range_freq_cutoffs  = 1:length(freq_cutoffs);
range_studies       = 1:length(studies);
range_exper_designs = 1:length(exper_designs);
range_smoothings    = 1:length(smoothings);
HRF_model           = 'gamma2_D';


cd(path_manage);
addpath(genpath([path_manage '/matlab_extra_functions']));
warning('off', 'MATLAB:mir_warning_maybe_uninitialized_temporary');


for software_id = range_softwares
   software = softwares{software_id};
   for freq_cutoff_id = range_freq_cutoffs
      freq_cutoff     = freq_cutoffs{freq_cutoff_id};
      if strcmp(software, 'AFNI') && strcmp(freq_cutoff, 'different')
         continue;
      end
      for study_id = range_studies
         study       = studies_parameters.study{study_id};
         abbr        = studies_parameters.abbr{study_id};
         task        = studies_parameters.task{study_id};
         no_subjects = studies_parameters.n(study_id);
         disp([software ' ' freq_cutoff ' ' study]);
         cd(path_manage);
         parfor subject_id = 1:no_subjects
            subject = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
            combined_parfor = (-1)*ones(length(smoothings), length(exper_designs));
            %-suppressing warnings about changes to variable names within the tables
            warning('off', 'MATLAB:table:ModifiedVarnames');
            for smoothing_id = range_smoothings
               smoothing = smoothings(smoothing_id);
               for exper_design_id = range_exper_designs
                  exper_design = exper_designs{exper_design_id};
                  cd([path_output study '/' software '/freq_cutoffs_' freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model]);
                  if exist(subject, 'dir') == 7
                     cd(subject);
                  else
                     disp([pwd ' ' subject]);
                  end
                  if exist('standardized_stats/pos_mask_MNI.mat', 'file') == 2
                     data = load('standardized_stats/pos_mask_MNI.mat');
                     combined_parfor(smoothing_id, exper_design_id) = sum(reshape(data.pos_mask_MNI, 1, []) > 0.5);
                  else
                     disp(pwd);
                  end
               end
            end
            combined(software_id, freq_cutoff_id, study_id, subject_id, :, :) = combined_parfor;
         end
      end
   end
end

for i1 = 1:dims(1)
   for i2 = 1:dims(2)
      for i3 = 1:dims(3)
         for i5 = 1:dims(5)
            for i6 = 1:dims(6)
               over_sub = combined(i1, i2, i3, :, i5, i6);
               %-(-0.5) chosen for numerical reasons; in fact, we only want to distinguish >=0 from <0
               if sum(over_sub>-0.5) > 0
                  pos_rates       (i1, i2, i3,    i5, i6) =  sum(over_sub>0)/sum(over_sub>-0.5);
                  %-sum(over_sub<-0.5) considered, as that many times the default (-1) is subtracted; (-1) appears in 'combined' for non-subjects
                  pos_mean_numbers(i1, i2, i3,    i5, i6) = (sum(over_sub) + sum(over_sub<-0.5)) / sum(over_sub>-0.5);
               end
            end
         end
      end
   end
end

cd(path_manage);
save('combined_results/combined',         'combined');
save('combined_results/pos_rates',        'pos_rates');
save('combined_results/pos_mean_numbers', 'pos_mean_numbers');
