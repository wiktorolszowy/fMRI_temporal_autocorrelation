
%-Wiktor Olszowy

path_manage        = fgetl(fopen('path_manage.txt'));
path_scratch       = fgetl(fopen('path_scratch.txt'));
studies_parameters = readtable([path_manage '/studies_parameters.txt']);
studies            = studies_parameters.study;
softwares          = cellstr(['AFNI'; 'FSL '; 'SPM ']);
freq_cutoffs       = cellstr(['freq_cutoffs_different'; 'freq_cutoffs_same     ']);
smoothings         = [0 4 5 8];
exper_designs      = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40']);
HRF_model          = 'gamma2_D';

addpath(genpath([path_manage '/matlab_extra_functions']));


%-make folders
parfor study_id = 1:length(studies)
   study = studies{study_id};
   cd(path_scratch);
   system(['mkdir analysis_output_' study]);
   for software_id = 1:length(softwares)
      software = softwares{software_id};
      cd([path_scratch '/analysis_output_' study]);
      system(['mkdir ' software]);
      path_output = [path_scratch '/analysis_output_' study '/' software];
      cd(path_output);
      system('mkdir freq_cutoffs_different');
      system('mkdir freq_cutoffs_same');
      for freq_cutoff_id = 1:2
         freq_cutoff = freq_cutoffs{freq_cutoff_id};
         for smoothing_id = 1:length(smoothings)
            smoothing = smoothings(smoothing_id);
            path_output_freq = [path_output '/' freq_cutoff];
            cd(path_output_freq);
            system(['mkdir smoothing_' num2str(smoothing)]);
            path_output_freq_smoothing = [path_output_freq '/smoothing_' num2str(smoothing)];
            for exper_design_id = 1:length(exper_designs)
               exper_design = exper_designs{exper_design_id};
               cd(path_output_freq_smoothing)
               system(['mkdir exper_design_', exper_design]);
               path_output_freq_smoothing_exper_design = [path_output_freq_smoothing '/exper_design_' exper_design];
               cd(path_output_freq_smoothing_exper_design);
	       %-make a folder to save the FSL 'preproc' designs and a folder to save the FSL 'preproc' analyses
               if strcmp(software, 'FSL')
                  system('mkdir preproc_feats_designs');
                  system('mkdir preproc_feats');
               else
                  system('mkdir preproc');
               end
               system(['mkdir HRF_' HRF_model]);
            end
         end
      end
   end
end
