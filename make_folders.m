
%-Wiktor Olszowy

path_manage        = fgetl(fopen('path_manage.txt'));
path_scratch       = fgetl(fopen('path_scratch.txt'));
studies_parameters = readtable([path_manage '/studies_parameters.txt']);
studies            = studies_parameters.study;
packages           = cellstr(['AFNI    '; 'FSL     '; 'SPM     '; 'SPM_FAST']);
smoothings         = [0 4 5 8];
exper_designs      = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40'; 'event1  '; 'event2  ']);
HRF_model          = 'gamma2_D';

addpath(genpath([path_manage '/matlab_extra_functions']));


%-make folders
parfor study_id = 1:length(studies)

   study = studies{study_id};
   cd(path_scratch);
   system(['mkdir analysis_output_' study]);

   for package_id = 1:length(packages)

      package = packages{package_id};
      cd([path_scratch '/analysis_output_' study]);
      system(['mkdir ' package]);
      path_output = [path_scratch '/analysis_output_' study '/' package];

      for smoothing_id = 1:length(smoothings)

         smoothing = smoothings(smoothing_id);
         cd(path_output);
         system(['mkdir smoothing_' num2str(smoothing)]);
         path_output_smoothing = [path_output '/smoothing_' num2str(smoothing)];

         for exper_design_id = 1:length(exper_designs)

            exper_design = exper_designs{exper_design_id};
            cd(path_output_smoothing)
            system(['mkdir exper_design_', exper_design]);
            path_output_smoothing_exper_design = [path_output_smoothing '/exper_design_' exper_design];
            cd(path_output_smoothing_exper_design);

            %-make a folder to save the FSL 'preproc' designs and a folder to save the FSL 'preproc' analyses
            if strcmp(package, 'FSL')
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
