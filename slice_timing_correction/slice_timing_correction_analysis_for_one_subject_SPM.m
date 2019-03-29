

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   SPM analysis for 1 fMRI scan, for different combinations of options.
%%%%   This is an additional analysis investigating the impact of slice timing correction.
%%%%   It was performed only for the 'CRIC checkerboard' and 'CamCAN' datasets, only for
%%%%   smoothing of 8 mm and only for the true designs.
%%%%   Written by:    Wiktor Olszowy, University of Cambridge
%%%%   Contact:       olszowyw@gmail.com
%%%%   Created:       February 2017 - August 2018
%%%%   Adapted from:  https://github.com/wanderine/ParametricMultisubjectfMRI/tree/master/SPM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


path_manage         = fgetl(fopen('path_manage.txt'));
path_scratch        = fgetl(fopen('path_scratch.txt'));
studies_parameters  = readtable([path_manage '/studies_parameters.txt']);
smoothings          = [0 4 5 8];
exper_designs       = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40'; 'event1  '; 'event2  ']);
randomOnsets        = textread([path_manage '/experimental_designs/SPM_randomOnsets.txt']);
randomDurations     = textread([path_manage '/experimental_designs/SPM_randomDurations.txt']);
randomOnsets_CamCAN = textread([path_manage '/experimental_designs/CamCAN_sensorimotor/SPM_randomOnsets_' repmat('0', 1, 4-length(num2str(subject_id)))       num2str(subject_id)       '.txt']);
HRF_model           = 'gamma2_D';
autocorr_options    = cellstr(['default'; 'FAST   ']);
study               = studies_parameters.study{study_id};
abbr                = studies_parameters.abbr{study_id};
task                = studies_parameters.task{study_id};
subject             = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
bold_file           = [subject '_' task '_bold'];
TR                  = studies_parameters.TR(study_id);      %-the repetition time
npts                = studies_parameters.npts(study_id);    %-the number of time points
max_index           = max(find((randomOnsets+4)<npts*TR));  %-4s was the longest possible activation time in design "event2", later the durations were changed to zero
path_data           = [path_scratch '/scans_' study];
path_output_top     = [path_scratch '/analysis_output_' study '/SPM'];

addpath(genpath([path_manage '/matlab_extra_functions']));
addpath('/applications/spm/spm12_7219');


for autocorr_option_id = 1:length(autocorr_options)

   autocorr_option     = autocorr_options{autocorr_option_id};

   if strcmp(study, 'CRIC_checkerboard')
      exper_design_id  = 4;
   elseif strcmp(study, 'CamCAN_sensorimotor')
      exper_design_id  = 17;
   end
   exper_design        = exper_designs{exper_design_id};
   
   %-for CamCAN data, only some experimental designs
   %if strcmp(study, 'CamCAN_sensorimotor') && ~strcmp(exper_design, 'boxcar10') && ~strcmp(exper_design, 'boxcar40') && ~strcmp(exper_design, 'event1') && ~strcmp(exper_design, 'event2')
   %   continue
   %end

   %-for other datasets, no 'event1' and no 'event2'
   %if ~strcmp(study, 'CamCAN_sensorimotor') && (strcmp(exper_design, 'event1') || strcmp(exper_design, 'event2'))
   %   continue
   %end
   
   path_output      = [path_output_top '/smoothing_8/exper_design_' exper_design];
   path_preproc_top = [path_output '/preproc_slice_timing_correction'];
   path_preproc     = [path_output_top '/smoothing_8/exper_design_' exper_design '/preproc_slice_timing_correction/' subject];

   %-initialise SPM defaults
   spm('Defaults', 'fMRI');
   spm_jobman('initcfg');
   clear jobs;
   %-default in SPM is 128, but in FSL it is 100
   spm_get_defaults('stats.fmri.hpf', 100);
   
   if strcmp(autocorr_option, 'default')
      
      cd(path_preproc_top);
      system(['mkdir ' subject]);
      path_preproc = [path_preproc_top '/' subject];
      cd(path_preproc);
      %-copy the scans
      system(['cp ' path_data '/' bold_file '.nii '           path_preproc]);
      system(['cp ' path_data '/' subject   '_T1w.nii '       path_preproc]);
      system(['cp ' path_data '/' subject   '_T1w_brain.nii ' path_preproc]);

      %-REALIGN (motion correction)
      job_no = 1;
      filename = [path_preproc '/' bold_file '.nii'];
      jobs{job_no}.spatial{1}.realign{1}.estwrite.data{1} = cellstr(filename);
      spm_jobman('run', jobs);

      %-slice timing correction
      %-page 250 of https://www.fil.ion.ucl.ac.uk/spm/doc/spm12_manual.pdf
      clear jobs;
      if strcmp(study, 'CRIC_checkerboard')
         nslices                              = 32;
         jobs{job_no}.temporal{1}.st.scans{1} = spm_select('expand', cellstr(spm_file(filename, 'prefix', 'r')));
         jobs{job_no}.temporal{1}.st.nslices  = nslices;
         jobs{job_no}.temporal{1}.st.tr       = TR;
         jobs{job_no}.temporal{1}.st.ta       = TR - (TR/nslices);
         jobs{job_no}.temporal{1}.st.so       = [2:2:nslices 1:2:nslices];
         jobs{job_no}.temporal{1}.st.refslice = round(nslices/2);
      elseif strcmp(study, 'CamCAN_sensorimotor')
         nslices                              = 32;
         jobs{job_no}.temporal{1}.st.scans{1} = spm_select('expand', cellstr(spm_file(filename, 'prefix', 'r')));
         jobs{job_no}.temporal{1}.st.nslices  = nslices;
         jobs{job_no}.temporal{1}.st.tr       = TR;
         jobs{job_no}.temporal{1}.st.ta       = TR - (TR/nslices);
         jobs{job_no}.temporal{1}.st.so       = nslices:-1:1;
         jobs{job_no}.temporal{1}.st.refslice = round(nslices/2);
      end
      
      %-SMOOTHING
      for smoothing_id = 4 %1:length(smoothings)
         smoothing                             = smoothings(smoothing_id);
         job_no                                = job_no + 1;
         filename                              = [path_preproc '/ar' bold_file '.nii'];
         jobs{job_no}.spatial{1}.smooth.data   = cellstr(filename);
         jobs{job_no}.spatial{1}.smooth.prefix = ['s' num2str(smoothing)];
         jobs{job_no}.spatial{1}.smooth.fwhm   = [smoothing smoothing smoothing];
      end

      spm_jobman('run', jobs);
      
      %-registration to MNI space is later conducted using transformations from FSL
      
   end
   
   for smoothing_id  = 4 %1:length(smoothings)

      smoothing      = smoothings(smoothing_id);

      %-for CamCAN data, only smoothing 8 mm
      %if strcmp(study, 'CamCAN_sensorimotor') && smoothing ~= 8
      %   continue
      %end
      
      %-ESTIMATION OF STATISTICAL MAPS

      path_output    = [path_output_top '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '_slice_timing_correction'];
      if strcmp(autocorr_option, 'FAST')
         path_output = strrep(path_output, 'SPM', 'SPM_FAST');
      end
      cd(path_output);
      disp([study, ' ', num2str(smoothing), ' ', exper_design, ' ', HRF_model, ' ', subject]);
      clear jobs;
      
      %-checking if the subject already analyzed
      if (7==exist(subject, 'dir')==1)
         cd(subject);
         %-don't forget that 'dir' returns two elements more; btw the threshold should be dataset-dependent (as numbers of time points = numbers of 'Res_'s different)
         if length(dir)>235
            likely_complete = 1;
            cd ..
         else
            likely_complete = 0;
            cd ..
            rmdir(subject, 's');
         end
      else
         likely_complete    = 0;
      end
      
      if (7==exist(subject, 'dir')==0) || (likely_complete==0)
         
         system(['mkdir ' subject]);
         filename                                = [path_output '/' subject];
         jobs{1}.stats{1}.fmri_spec.dir          = cellstr(filename);
         jobs{1}.stats{1}.fmri_spec.timing.units = 'secs';
         jobs{1}.stats{1}.fmri_spec.timing.RT    = TR;
         scans = {};
         for t = 1:npts
            scans{t} = [path_preproc '/s' num2str(smoothing) 'ar' bold_file '.nii,' num2str(t)];
         end
         jobs{1}.stats{1}.fmri_spec.sess.scans        = transpose(scans);
         jobs{1}.stats{1}.fmri_spec.sess.cond(1).name = 'task1';
         
         %-specifying the experimental design
         if strcmp(exper_design(1:6), 'boxcar')
            len = str2num(exper_design(7:8));
            jobs{1}.stats{1}.fmri_spec.sess.cond(1).onset    = len:(2*len):(npts*TR-len);
            jobs{1}.stats{1}.fmri_spec.sess.cond(1).duration = len;
         elseif strcmp(exper_design, 'event1')
            jobs{1}.stats{1}.fmri_spec.sess.cond(1).onset    = randomOnsets_CamCAN;
            jobs{1}.stats{1}.fmri_spec.sess.cond(1).duration = 0.1;
         elseif strcmp(exper_design, 'event2')
            jobs{1}.stats{1}.fmri_spec.sess.cond(1).onset    = randomOnsets(1:max_index);
            jobs{1}.stats{1}.fmri_spec.sess.cond(1).duration = 0.1;
         end
         
         %-including motion regressors in the GLM
         jobs{1}.stats{1}.fmri_spec.sess.multi_reg           = {[path_preproc '/rp_' bold_file '.txt']};
         
         %-HRF: canonical with 1st derivative
         jobs{1}.stats{1}.fmri_spec.bases.hrf.derivs         = [1 0];
         
         %-specifying autocorrelation modeling technique
         if strcmp(autocorr_option, 'FAST')
            jobs{1}.stats{1}.fmri_spec.cvi                   = 'FAST';
         end
         
         filename_mat                                = [filename '/SPM.mat'];
         jobs{1}.stats{2}.fmri_est.spmmat            = cellstr(filename_mat);
         jobs{1}.stats{3}.con.spmmat                 = cellstr(filename_mat);
         jobs{1}.stats{3}.con.consess{1}.tcon        = struct('name', 'task1 > rest', 'convec', 1, 'sessrep', 'none');
         jobs{1}.stats{4}.results.spmmat             = cellstr(filename_mat);
         jobs{1}.stats{4}.results.conspec.contrasts  = 1;
         jobs{1}.stats{4}.results.conspec.threshdesc = 'none';
         jobs{1}.stats{4}.results.conspec.thresh     = 0.001;
         jobs{1}.stats{4}.results.conspec.extent     = 0;
         jobs{1}.stats{4}.results.print              = false;

         spm_jobman('run', jobs);
         %-saving/not removing GLM residuals
         VRes = spm_write_residuals(SPM, NaN);
         
      end
      
      %-multiple comparison correction later performed via FSL
      
   end

end

cd(path_manage)
