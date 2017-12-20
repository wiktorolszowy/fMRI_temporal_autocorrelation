

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   SPM analysis for 1 fMRI scan, for different combinations of options.
%%%%   Written by:    Wiktor Olszowy, University of Cambridge
%%%%   Contact:       wo222@cam.ac.uk
%%%%   Created:       February-December 2017
%%%%   Adapted from:  https://github.com/wanderine/ParametricMultisubjectfMRI/tree/master/SPM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


path_manage        = fgetl(fopen('path_manage.txt'));
path_scratch       = fgetl(fopen('path_scratch.txt'));
studies_parameters = readtable([path_manage '/studies_parameters.txt']);
smoothings         = [0 4 5 8];
freq_cutoffs       = cellstr(['different'; 'same     ']);
freq_cutoff        = 'same';
exper_designs      = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40']);
HRF_model          = 'gamma2_D';
voxel_size         = 2;
window_length      = 24;                                   %-[seconds]
study              = studies_parameters.study{study_id};
abbr               = studies_parameters.abbr{study_id};
task               = studies_parameters.task{study_id};
subject            = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
bold_file          = [subject '_' task '_bold'];
TR                 = studies_parameters.TR(study_id);      %-the repetition time
npts               = studies_parameters.npts(study_id);    %-the number of time points
path_data          = [path_scratch '/scans_' study];
path_output_top    = [path_scratch '/analysis_output_' study '/SPM/freq_cutoffs_' freq_cutoff];

addpath(genpath([path_manage '/matlab_extra_functions']));


for exper_design_id = 1:length(exper_designs)
   exper_design     = exper_designs{exper_design_id};
   path_output      = [path_output_top '/smoothing_' num2str(smoothings(1)) '/exper_design_' exper_design];
   path_preproc_top = [path_output '/preproc'];
   if strcmp(exper_design, exper_designs{1}) || strcmp(freq_cutoff, 'different')
      
      %-initialise SPM defaults
      spm('Defaults', 'fMRI');
      spm_jobman('initcfg');
      clear jobs;
      
      if strcmp(freq_cutoff, 'same')
         %-default in SPM is 128, but in FSL it is 100
         spm_get_defaults('stats.fmri.hpf', 100);
      else
         %-SPM sometimes removes the signal at the cutoff frequency too (opposed to FSL), that's why +10
         spm_get_defaults('stats.fmri.hpf', 10+2*str2double(exper_design(7:8)));
      end
      cd(path_preproc_top);
      system(['mkdir ' subject]);
      
      %-when 'same' cutoff frequency considered, 'path_preproc' from exper_designs{1} for all exper_designs
      path_preproc = [path_preproc_top '/' subject];
      cd(path_preproc);
      
      %-copy the scans
      system(['cp ' path_data '/' bold_file '.nii '           path_preproc]);
      system(['cp ' path_data '/' subject   '_T1w.nii '       path_preproc]);
      system(['cp ' path_data '/' subject   '_T1w_brain.nii ' path_preproc]);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      %-SPATIAL PREPROCESSING
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      %-REALIGN (motion correction)
      job_no = 1;
      
      filename = [path_preproc '/' bold_file '.nii'];
      jobs{job_no}.spatial{1}.realign{1}.estwrite.data{1} = cellstr(filename);
      
      %-registration to MNI space is later conducted using transformations from FSL
      %{
      %-COREGISTRATION, fMRI and T1w
      job_no                                                   = job_no + 1;
      filename                                                 = [path_preproc '/mean' bold_file '.nii'];
      jobs{job_no}.spatial{1}.coreg{1}.estimate.ref            = {[filename ',1']};
      filename                                                 = [path_preproc '/' subject '_T1w.nii'];
      jobs{job_no}.spatial{1}.coreg{1}.estimate.source         = {[filename ',1']};
      %-SEGMENT
      job_no                                                   = job_no + 1;
      filename                                                 = [path_preproc '/' subject '_T1w.nii'];
      jobs{job_no}.spatial{1}.preproc.data                     = {[filename ',1']};
      %-NORMALIZE (using transformation from segment)
      job_no                                                   = job_no + 1;
      matname                                                  = [path_preproc '/' subject, '_T1w_seg_sn.mat'];
      jobs{job_no}.spatial{1}.normalise{1}.write.subj.matname  = cellstr(matname);
      filename                                                 = [path_preproc '/r' bold_file '.nii'];
      jobs{job_no}.spatial{1}.normalise{1}.write.subj.resample = cellstr(filename);
      jobs{job_no}.spatial{1}.normalise{1}.write.roptions.vox  = [voxel_size voxel_size voxel_size];
      jobs{job_no}.spatial{1}.normalise{2}.write.subj.matname  = cellstr(matname);
      filename                                                 = [path_preproc '/' subject '_T1w.nii'];
      jobs{job_no}.spatial{1}.normalise{2}.write.subj.resample = cellstr(filename);
      jobs{job_no}.spatial{1}.normalise{2}.write.roptions.vox  = [1 1 1];
      %}
      
      %-SMOOTHING
      for smoothing_id = 1:length(smoothings)
         smoothing = smoothings(smoothing_id);
         job_no                                                = job_no + 1;
         filename                                              = [path_preproc '/r' bold_file '.nii'];
         jobs{job_no}.spatial{1}.smooth.data                   = cellstr(filename);
         jobs{job_no}.spatial{1}.smooth.prefix                 = ['s' num2str(smoothing)];
         jobs{job_no}.spatial{1}.smooth.fwhm                   = [smoothing smoothing smoothing];        
      end
      
      %-RUN
      spm_jobman('run', jobs);
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   %-STATISTICAL ANALYSIS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   for smoothing_id = 1:length(smoothings)
      smoothing = smoothings(smoothing_id);         
      
      path_output  = [path_output_top '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model];
      cd(path_output);
      disp([study, ' ', num2str(smoothing), ' ', exper_design, ' ', HRF_model, ' ', subject]);            
      clear jobs;
      
      %-MODEL SPECIFICATION AND ESTIMATION         
      if (7==exist(subject, 'dir')==0)
         system(['mkdir ' subject]);
         filename = [path_output '/' subject];
         
         jobs{1}.stats{1}.fmri_spec.dir          = cellstr(filename);
         jobs{1}.stats{1}.fmri_spec.timing.units = 'secs';
         jobs{1}.stats{1}.fmri_spec.timing.RT    = TR;
         
         scans = {};
         for t = 1:npts
            scans{t} = [path_preproc '/s' num2str(smoothing) 'r' bold_file '.nii,' num2str(t)];
         end
         jobs{1}.stats{1}.fmri_spec.sess.scans        = transpose(scans);
         jobs{1}.stats{1}.fmri_spec.sess.cond(1).name = 'task1';
         
         %-all designs are boxcar designs
         len = str2double(exper_design(7:8));
         jobs{1}.stats{1}.fmri_spec.sess.cond(1).onset       = len:(2*len):(npts*TR-len);
         jobs{1}.stats{1}.fmri_spec.sess.cond(1).duration    = len;
         
         %-motion regressors
         jobs{1}.stats{1}.fmri_spec.sess.multi_reg           = {[path_preproc '/rp_' bold_file '.txt']};
         
         %-HRF: canonical with 1st derivative
         jobs{1}.stats{1}.fmri_spec.bases.hrf.derivs         = [1 0];
         
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
         
         filename       = [path_output '/' subject];
         filename_mat   = [filename '/SPM.mat'];
         cd(filename);
         
         %-get t-map
         V              = spm_vol([path_output  '/' subject '/spmT_0001.nii']);
         [tmap,aa]      = spm_read_vols(V);
         %-load SPM file
         clear SPM;
         load(filename_mat);
         %-calculate cluster extent threshold
         [k,Pc]         = corrclusth(SPM, 0.001, 0.05, 1:100000);
         STAT           = 'T';
         df             = [1 SPM.xX.erdf];
         %-using the default cluster defining threshold (CDT) of 0.001
         u              = spm_u(0.001, df, STAT);
         indices        = find(tmap>u);
         %-to check if the number of indices agrees with the SPM plot
         fid            = fopen('indices.txt', 'wt');
         fprintf(fid, '%8.0f\n', indices);
         
         %-get the size of the largest cluster
         max_cluster    = max_extent(tmap, indices);
         if max_cluster >= k
            indices     = find(tmap>u);
         else
            indices     = '';
         end;
         fid            = fopen('indices.txt', 'wt');
         fprintf(fid, '%8.0f\n', indices);
         
         clear jobs;
         jobs{1}.stats{1}.results.spmmat             = cellstr(filename_mat);
         jobs{1}.stats{1}.results.conspec.contrasts  = 1;
         jobs{1}.stats{1}.results.conspec.threshdesc = 'none';
         jobs{1}.stats{1}.results.conspec.thresh     = 0.001;
         jobs{1}.stats{1}.results.conspec.extent     = 0;
         jobs{1}.stats{1}.results.print              = true;
         spm_jobman('run', jobs);

         VRes = spm_write_residuals(SPM,NaN);
         
      end
   end
end
