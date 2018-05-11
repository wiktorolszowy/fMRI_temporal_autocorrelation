

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   Aim: investigate if pre-whitening in SPM affects group level analyses.
%%%%   Written by:    Wiktor Olszowy, University of Cambridge
%%%%   Contact:       wo222@cam.ac.uk
%%%%   Created:       May 2018
%%%%   Adapted from:  https://github.com/wanderine/ParametricMultisubjectfMRI/blob/master/SPM/run_random_group_analyses_onesamplettest_1.m
%%%%                  http://www.fil.ion.ucl.ac.uk/spm/data/face_rfx/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


path_manage         = fgetl(fopen('path_manage.txt'));
path_scratch        = fgetl(fopen('path_scratch.txt'));
studies_parameters  = readtable([path_manage '/studies_parameters.txt']);
exper_designs       = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40'; 'event1  '; 'event2  ']);
autocorr_options    = cellstr(['default'; 'FAST   ']);
HRF_model           = 'gamma2_D';
smoothing           = 8;


addpath(genpath([path_manage '/matlab_extra_functions']));
addpath('/applications/spm/spm12_7219');


spm('Defaults', 'fMRI');
spm_jobman('initcfg');


for autocorr_option_id = 1:length(autocorr_options)

   autocorr_option     = autocorr_options{autocorr_option_id};

   for exper_design_id = 1:length(exper_designs)

      exper_design     = exper_designs{exper_design_id};

      for study_id        = 1:11

         study            = studies_parameters.study{study_id};
         abbr             = studies_parameters.abbr{study_id};
         task             = studies_parameters.task{study_id};
         no_subjects      = studies_parameters.n(study_id);
         if strcmp(autocorr_option, 'default')
            path_output   = [path_scratch '/analysis_output_' study      '/SPM/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model];
         else
            path_output   = [path_scratch '/analysis_output_' study '/SPM_FAST/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model];
         end

         %-for CamCAN data, only some experimental designs
         if strcmp(study, 'CamCAN_sensorimotor') && ~strcmp(exper_design, 'boxcar10') && ~strcmp(exper_design, 'boxcar40') && ~strcmp(exper_design, 'event1') && ~strcmp(exper_design, 'event2')
            continue
         end

         %-for other datasets, no 'event1' and no 'event2'
         if ~strcmp(study, 'CamCAN_sensorimotor') && (strcmp(exper_design, 'event1') || strcmp(exper_design, 'event2'))
            continue
         end

         disp(path_output);
         disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');

         %-registering 'con_0001' to MNI space
         for subject_id   = 1:no_subjects
            subject       = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
            cd([path_output '/' subject]);
            if exist('standardized_stats/con_0001_MNI.nii', 'file') ~= 2
               system('flirt -ref standardized_stats/standard -in con_0001 -applyxfm -init standardized_stats/example_func2standard.mat -out standardized_stats/con_0001_MNI');
               system('gunzip standardized_stats/con_0001_MNI.nii.gz');
            end
         end

         cd(path_output);

         SPM_mat_location                                         = cellstr(fullfile(path_output, 'group_analysis', 'SPM.mat'));

         system('mkdir group_analysis');

         con_0001_MNI_all                                         = cellstr(spm_select('FPListRec', fullfile(path_output), '^con_0001_MNI.nii'));
         SPM_mat_location                                         = cellstr(fullfile(path_output, 'group_analysis', 'SPM.mat'));

         clear jobs;
         
         jobs{1}.stats{1}.factorial_design.dir                    = cellstr(fullfile(path_output, 'group_analysis'));
         jobs{1}.stats{1}.factorial_design.des.t1.scans           = con_0001_MNI_all;
         jobs{1}.stats{1}.factorial_design.cov                    = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
         jobs{1}.stats{1}.factorial_design.masking.tm.tm_none     = 1;
         jobs{1}.stats{1}.factorial_design.masking.im             = 1;
         jobs{1}.stats{1}.factorial_design.masking.em             = {''};
         jobs{1}.stats{1}.factorial_design.globalc.g_omit         = 1;
         jobs{1}.stats{1}.factorial_design.globalm.gmsca.gmsca_no = 1;
         jobs{1}.stats{1}.factorial_design.globalm.glonorm        = 1;

         jobs{1}.stats{2}.fmri_est.spmmat                         = SPM_mat_location;

         jobs{1}.stats{3}.con.spmmat                              = SPM_mat_location;
         jobs{1}.stats{3}.con.consess{1}.tcon                     = struct('name', 'group 1 > 0', 'convec', 1, 'sessrep', 'none');

         jobs{1}.stats{4}.results.spmmat                          = SPM_mat_location;
         jobs{1}.stats{4}.results.conspec.contrasts               = Inf;
         jobs{1}.stats{4}.results.conspec.threshdesc              = 'FWE';
         
         spm_jobman('run', jobs);

         %-get t-map
         V           = spm_vol([path_output '/group_analysis/spmT_0001.nii']);
         [tmap,aa]   = spm_read_vols(V);

         %-calculate cluster extent threshold
         [k,Pc]      = corrclusth(SPM, 0.001, 0.05, 1:100000);
         STAT        = 'T';
         df          = [1 SPM.xX.erdf];
         u           = spm_u(0.001, df, STAT);
         indices     = find(tmap>u);
         
         %-get the size of the largest cluster
         max_cluster = max_extent(tmap, indices);
         
         if max_cluster >= k
            indices     = find(tmap>u);
            disp([study ' ' num2str(smoothing) ' ' exper_design ': significant!']);
            disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
            disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
            disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
            disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
            disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
            disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
         else
            indices     = '';
         end
         fid            = fopen('indices.txt', 'wt');
         fprintf(fid, '%8.0f\n', indices);

      end

   end

end

cd(path_manage)
