

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   Figures comparing pre-whitening in AFNI/FSL/SPM.
%%%%   Written by:  Wiktor Olszowy, University of Cambridge
%%%%   Contact:     wo222@cam.ac.uk
%%%%   Created:     September 2016 - August 2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


paper                  = 'autocorr';
path_manage            = fgetl(fopen('path_manage.txt'));
path_scratch           = fgetl(fopen('path_scratch.txt'));
path_output            = [path_scratch '/analysis_output_'];
studies_parameters     = readtable([path_manage '/studies_parameters.txt']);
studies                = studies_parameters.study;
packages               = cellstr(['AFNI    '; 'FSL     '; 'SPM     '; 'SPM_FAST']);
smoothings             = [0 4 5 8];
exper_designs          = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40'; 'event1  '; 'event2  ']);
fig_size               = [0 0 550 745];
no_of_studies_for_dist = 10;
clims_studies          = [2   2   10  10  2   2   20    20    20   20    20];
exper_designs_exp_id   = [100 100 100 100 100 100 6     6     2    4     17];
freq_studies_exp_id    = [100 100 100 100 100 100 0.025 0.025 1/24 1/32  100];
exper_designs_dist     = cellstr(['boxcar12'; 'boxcar16'; 'boxcar20'; 'boxcar40']);
HRF_model              = 'gamma2_D';
colors                 = [0 1 0; 0 0 1; 1 0 1; 0.96 0.47 0.13];
studies_out            = cell.empty;
nrows                  = ceil((length(studies)-length(studies_out)+1)/2);
range_packages         = 1:length(packages);
range_studies          = 1:10; %-11th study (CamCAN) only for the last figure
range_exper_designs    = 1:16; %-17th and 18th designs only for the last figure
range_smoothings       = [2 4];
NumTicks               = length(range_exper_designs);

cd(path_manage);
addpath(genpath([path_manage '/matlab_extra_functions']));
warning('off', 'MATLAB:mir_warning_maybe_uninitialized_temporary');
warning('off', 'MATLAB:hg:AutoSoftwareOpenGL');

load('combined_results/combined.mat');
load('combined_results/pos_rates.mat');
load('combined_results/pos_mean_numbers.mat');
load('combined_results/pos_fractions.mat');

%-pmn stands for pos_mean_numbers
dims_pmn                         = size(pos_mean_numbers);
x_axis                           = range_exper_designs;
tmp_array                        = permute(pos_mean_numbers(:, :, :, 1:length(exper_designs)), [2 1 3 4]);
tmp_nrow                         = dims_pmn(2);
tmp_ncol                         = dims_pmn(1)*length(smoothings)*length(exper_designs)*1;
studies_mean_numbers_max         = max(reshape(tmp_array, tmp_nrow, tmp_ncol), [], 2);
tmp_array                        = permute(pos_fractions   (:, :, :, 1:length(exper_designs)), [2 1 3 4]);
studies_mean_fractions_max       = max(reshape(tmp_array, tmp_nrow, tmp_ncol), [], 2);

studies_labels = studies;
for study_id   = 1:length(studies)
   study       = studies{study_id};
   study_label = strrep(study, '_', ' ');
   study_label = strrep(study_label, '1400', 'TR=1.4s');
   study_label = strrep(study_label, '645',  'TR=0.645s');
   study_label = strrep(study_label, ' release 3',  '');
   study_label = strrep(study_label, 'FCP Beijing',              'FCP Beijing TR=2s');
   study_label = strrep(study_label, 'FCP Cambridge',            'FCP Cambridge TR=3s');
   study_label = strrep(study_label, 'BMMR checkerboard',        'BMMR checkerboard TR=3s');
   study_label = strrep(study_label, 'CRIC RS',                  'CRIC RS TR=2s');
   study_label = strrep(study_label, 'CRIC checkerboard',        'CRIC checkerboard TR=2s');
   study_label = strrep(study_label, 'simulated using neuRosim', 'neuRosim simulated TR=2s');
   study_label = strrep(study_label, 'CamCAN sensorimotor',      'CamCAN sensorimotor TR=1.97s');
   study_label = strrep(study_label, 'TR', '(TR');
   study_label = strrep(study_label, ' RS', '');
   study_label = [study_label ')'];
   if study_id < 7
      study_label = ['REST: ' study_label];
   else
      study_label = ['TASK: ' study_label];
   end
   studies_labels{study_id} = study_label;
end


for smoothing_id = range_smoothings
   smoothing = smoothings(smoothing_id);
   
   %%%%%%%%%%%%%%%%%%%%%%%% LINE PLOTS: POSITIVE RATES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
   study_id_plot  = 0;
   for study_id   = range_studies
      study       = studies{study_id};
      study_label = studies_labels{study_id};
      no_subjects = studies_parameters.n(study_id);
      if any(strcmp(studies_out, study))
         continue;
      else
         study_id_plot = study_id_plot + 1;
         subplot(nrows, 2, study_id_plot);
         %-the following 2 is arbitrarily chosen, does not change anything
         sd     = sqrt(0.05*0.95/no_subjects)*1.96*100;
         %-'100*' as percentages are used
         y_axes = 100*reshape(pos_rates(1:length(packages), study_id, smoothing_id, range_exper_designs), [4, length(range_exper_designs)]);
         h0     = plot([exper_designs_exp_id(study_id) exper_designs_exp_id(study_id)], [0 100], 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
         h1     = plot(x_axis, squeeze(y_axes(1,:)), 'color', colors(1, :));            hold on;
         h2     = plot(x_axis, squeeze(y_axes(2,:)), 'color', colors(2, :));            hold on;
         h3     = plot(x_axis, squeeze(y_axes(3,:)), 'color', colors(3, :));            hold on;
         h32    = plot(x_axis, squeeze(y_axes(4,:)), 'color', colors(4, :));            hold on;
         h15    = plot([0.5 NumTicks+0.5], [5 5], 'k');                                 hold on;
         h16    = plot([0.5 NumTicks+0.5], [5-sd 5-sd], '-.k', 'Color', [0.5 0.5 0.5]); hold on;
         h17    = plot([0.5 NumTicks+0.5], [5+sd 5+sd], '-.k', 'Color', [0.5 0.5 0.5]); hold on;
         if study_id_plot==9 || study_id_plot==10
            hx  = xlabel({' ', 'Assumed experimental design', ' '});
         else
            hx  = xlabel(' ');
         end
         hy     = ylabel('Positive rate (%)');
         htitle = title(study_label, 'interpreter', 'none');
         xlim([0.8 NumTicks+0.2]);
         ylim([0 100]);
         %-lowering vertical spacing between subplots
         pos    = get(gca, 'Position');
         pos(2) = pos(2)-0.023;
         set(gca, 'Position', pos);
         set([h1 h2 h3 h32 h15], 'LineWidth', 1.5);
         set([h16 h17],          'LineWidth', 1);
         set(gca, 'XTick', 1:NumTicks);
         set(gca, 'XTickLabel', 10:2:40);
         set(gca, 'FontSize', 7);
         set([hx hy htitle], 'FontSize', 7);
      end
   end
   fig_ref = subplot(nrows, 2, nrows*2);
   plot(1);
   set(gca, 'visible', 'off');
   %-buffer values: first value down -> text to the left; second value down -> text down
   hlegend = legendflex([h1 h2 h3 h32 h0 h15 h16], {'AFNI', 'FSL', 'SPM', 'SPM with option FAST', 'True experimental design', 'Expected rate for null data', '95% confidence interval'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer', [-260 -15], 'box', 'off', 'FontSize', 7, 'nrow', 4);
   set(hlegend, 'FontSize', 7);
   figname = [paper '_rates_smoothing_' num2str(smoothing)];
   print_to_svg_to_pdf(figname, path_manage);
   
   %%%%%%%%%%%%%%%%%%%%%%%% LINE PLOTS: MEAN NUMBERS OF SIGNIFICANT VOXELS %%%%%%%%%%%%%%%%%%%%%%%%%%
   figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
   study_id_plot  = 0;
   for study_id   = range_studies
      study       = studies{study_id};
      study_label = studies_labels{study_id};
      if any(strcmp(studies_out, study))
         continue;
      else
         study_id_plot = study_id_plot + 1;
         subplot(nrows, 2, study_id_plot);
         y_axes = reshape(pos_mean_numbers(1:length(packages), study_id, smoothing_id, range_exper_designs), [4, length(range_exper_designs)]);
         h0     = plot([exper_designs_exp_id(study_id) exper_designs_exp_id(study_id)], [0 1000000000], 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
         h1     = plot(x_axis, squeeze(y_axes(1,:)), 'color', colors(1, :)); hold on;
         h2     = plot(x_axis, squeeze(y_axes(2,:)), 'color', colors(2, :)); hold on;
         h3     = plot(x_axis, squeeze(y_axes(3,:)), 'color', colors(3, :)); hold on;
         h32    = plot(x_axis, squeeze(y_axes(4,:)), 'color', colors(4, :)); hold on;
         if study_id_plot==9 || study_id_plot==10
            hx  = xlabel({' ', 'Assumed experimental design', ' '});
         else
            hx  = xlabel(' ');
         end
         hy     = ylabel('Mean #(sig vox)', 'Units', 'normalized');
         htitle = title(study_label, 'interpreter', 'none');
         xlim([0.8 NumTicks+0.2]);
         ylim([0 studies_mean_numbers_max(study_id)]);
         %-lowering vertical spacing between subplots
         pos    = get(gca, 'Position');
         pos(2) = pos(2)-0.023;
         set(gca, 'Position', pos);
         set([h1 h2 h3 h32], 'LineWidth', 1.5);
         set(gca, 'XTick', 1:NumTicks);
         set(gca, 'XTickLabel', 10:2:40);
         set(gca, 'FontSize', 7);
         ax = gca;
         %-scientific/exponential notation on the y-axis
         ax.YAxis.Exponent = 3;
         set([hx hy htitle], 'FontSize', 7);
         %-controlling distance between y axis title and y axis
         hy_pos    = get(hy, 'Position');
         hy_pos(1) = -0.11;
         set(hy, 'Position', hy_pos);
      end
   end
   fig_ref = subplot(nrows, 2, nrows*2);
   plot(1);
   set(gca, 'visible', 'off');
   hlegend = legendflex([h1 h2 h3 h32 h0], {'AFNI', 'FSL', 'SPM', 'SPM with option FAST', 'True experimental design'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer', [-260 -15], 'box', 'off', 'FontSize', 7, 'nrow', 4);
   set(hlegend, 'FontSize', 7);
   figname = [paper '_mean_numbers_smoothing_' num2str(smoothing)];
   print_to_svg_to_pdf(figname, path_manage);

   %%%%%%%%%%%%%%%%%%%%%%%% LINE PLOTS: MEAN FRACTIONS OF SIGNIFICANT VOXELS %%%%%%%%%%%%%%%%%%%%%%%%
   figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
   study_id_plot  = 0;
   for study_id   = range_studies
      study       = studies{study_id};
      study_label = studies_labels{study_id};
      if any(strcmp(studies_out, study))
         continue;
      else
         study_id_plot = study_id_plot + 1;
         subplot(nrows, 2, study_id_plot);
         %-'100*' as percentages are used
         y_axes = 100*reshape(pos_fractions(1:length(packages), study_id, smoothing_id, range_exper_designs), [4, length(range_exper_designs)]);
         h0     = plot([exper_designs_exp_id(study_id) exper_designs_exp_id(study_id)], [0 1000000000], 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
         h1     = plot(x_axis, squeeze(y_axes(1,:)), 'color', colors(1, :)); hold on;
         h2     = plot(x_axis, squeeze(y_axes(2,:)), 'color', colors(2, :)); hold on;
         h3     = plot(x_axis, squeeze(y_axes(3,:)), 'color', colors(3, :)); hold on;
         h32    = plot(x_axis, squeeze(y_axes(4,:)), 'color', colors(4, :)); hold on;
         if study_id_plot==9 || study_id_plot==10
            hx  = xlabel({' ', 'Assumed experimental design', ' '});
         else
            hx  = xlabel(' ');
         end
         hy     = ylabel('Avg. % of sig voxels', 'Units', 'normalized');
         htitle = title(study_label, 'interpreter', 'none');
         xlim([0.8 NumTicks+0.2]);
         ylim([0 100*studies_mean_fractions_max(study_id)]);
         %-lowering vertical spacing between subplots
         pos    = get(gca, 'Position');
         pos(2) = pos(2)-0.023;
         set(gca, 'Position', pos);
         set([h1 h2 h3 h32], 'LineWidth', 1.5);
         set(gca, 'XTick', 1:NumTicks);
         set(gca, 'XTickLabel', 10:2:40);
         set(gca, 'FontSize', 7);
         set([hx hy htitle], 'FontSize', 7);
         %-controlling distance between y axis title and y axis
         hy_pos    = get(hy, 'Position');
         hy_pos(1) = -0.14;
         set(hy, 'Position', hy_pos);
      end
   end
   fig_ref = subplot(nrows, 2, nrows*2);
   plot(1);
   set(gca, 'visible', 'off');
   hlegend = legendflex([h1 h2 h3 h32 h0], {'AFNI', 'FSL', 'SPM', 'SPM with option FAST', 'True experimental design'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer', [-260 -15], 'box', 'off', 'FontSize', 7, 'nrow', 4);
   set(hlegend, 'FontSize', 7);
   figname = [paper '_mean_fractions_smoothing_' num2str(smoothing)];
   print_to_svg_to_pdf(figname, path_manage);

end


%%%%%%%%%%%%%%%%%%%%%%%% POWER SPECTRA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for exper_design_id = [1 16]
   exper_design     = exper_designs{exper_design_id};
   %-finding maximum values on the y axis across different smoothings
   max_y_axis       = zeros(length(range_studies), 1);
   for smoothing_id = [2 4]
      smoothing     = smoothings(smoothing_id);
      for study_id  = range_studies
         study      = studies{study_id};
         power_spectra_AFNI     = load([path_output study '/AFNI/smoothing_'     num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_FSL      = load([path_output study '/FSL/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_SPM      = load([path_output study '/SPM/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_SPM_FAST = load([path_output study '/SPM_FAST/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_AFNI     = power_spectra_AFNI.power_spectra;
         power_spectra_FSL      = power_spectra_FSL.power_spectra;
         power_spectra_SPM      = power_spectra_SPM.power_spectra;
         power_spectra_SPM_FAST = power_spectra_SPM_FAST.power_spectra;
         max_y_axis(study_id) = max(vertcat(max_y_axis(study_id), power_spectra_AFNI, power_spectra_FSL, power_spectra_SPM, power_spectra_SPM_FAST));
      end
   end
   for smoothing_id   = [2 4]
      smoothing       = smoothings(smoothing_id);
      study_id_plot   = 0;
      figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
      for study_id    = range_studies
         study        = studies{study_id};
         study_label  = studies_labels{study_id};
         TR           = studies_parameters.TR(study_id);
         power_spectra_AFNI     = load([path_output study '/AFNI/smoothing_'     num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_FSL      = load([path_output study '/FSL/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_SPM      = load([path_output study '/SPM/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_SPM_FAST = load([path_output study '/SPM_FAST/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_AFNI     = power_spectra_AFNI.power_spectra;
         power_spectra_FSL      = power_spectra_FSL.power_spectra;
         power_spectra_SPM      = power_spectra_SPM.power_spectra;
         power_spectra_SPM_FAST = power_spectra_SPM_FAST.power_spectra;
         f = linspace(0, 0.5/TR, 257);
         if any(strcmp(studies_out, study))
            continue;
         else
            study_id_plot = study_id_plot + 1;
            subplot(nrows, 2, study_id_plot);
            h1         = plot(f, power_spectra_AFNI(1:257),     'color', colors(1, :));       hold on;
            h2         = plot(f, power_spectra_FSL(1:257),      'color', colors(2, :));       hold on;
            h3         = plot(f, power_spectra_SPM(1:257),      'color', colors(3, :));       hold on;
            h32        = plot(f, power_spectra_SPM_FAST(1:257), 'color', colors(4, :));       hold on;
            h4         = plot(freq_studies_exp_id(study_id),    0,                    'k*');  hold on;
            h5         = plot(freq_studies_exp_id(study_id),    max_y_axis(study_id), 'k*');  hold on;
            h6         = plot(1/(2*str2num(exper_design(7:8))), 0,                    'c*');  hold on;
            h7         = plot(1/(2*str2num(exper_design(7:8))), max_y_axis(study_id), 'c*');  hold on;
            %h8        = plot(1/100,                            0,                    'm*');  hold on;
            %h9        = plot(1/100,                            max_y_axis(study_id), 'm*');  hold on;
            h80        = plot([0 0.5/TR], [1 1],                                      'k--'); hold on;
            if study_id_plot==9 || study_id_plot==10
               hx  = xlabel({' ', 'Frequency [Hz]', ' '});
            else
               hx  = xlabel('');
            end
            hy     = ylabel('Power spectra', 'Units', 'normalized');
            htitle = title(study_label, 'interpreter', 'none');
            xlim([0 0.5/TR]);
            ylim([0 max_y_axis(study_id)]);
            %-lowering vertical spacing between subplots
            pos    = get(gca, 'Position');
            pos(2) = pos(2)-0.023;
            set(gca, 'Position', pos);
            set([h1 h2 h3 h32 h80], 'LineWidth', 1.25);
            set(gca, 'XTick', linspace(0, 0.5/TR, 6));
            set(gca, 'XTickLabel', round(linspace(0, 0.5/TR, 6), 2));
            set(gca, 'FontSize', 7);
            set([hx hy htitle], 'FontSize', 7);
            %-controlling distance between y axis title and y axis
            hy_pos    = get(hy, 'Position');
            hy_pos(1) = -0.11;
            set(hy, 'Position', hy_pos);
         end
      end
      fig_ref = subplot(nrows, 2, nrows*2);
      plot(1);
      set(gca, 'visible', 'off');
      hlegend = legendflex([h1 h2 h3 h32 h80 h4 h6], {'AFNI', 'FSL', 'SPM', 'SPM with option FAST', 'Ideal power spectra', 'True design frequency', 'Assumed design frequency'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer',  [-260 -15], 'box', 'off', 'FontSize', 7, 'nrow', 4);
      set(hlegend, 'FontSize', 7);
      figname = [paper '_power_smoothing_' num2str(smoothing) '_exper_design_' exper_design];
      print_to_svg_to_pdf(figname, path_manage);
   end
end


%%%%%%%%%%%%%%%%%%%%%%%% POWER SPECTRA: 1ST SUBJECT IN EACH DATASET ONLY %%%%%%%%%%%%%%%%%%%%%%%%%
for exper_design_id   = [1 16]
   exper_design       = exper_designs{exper_design_id};
   %-finding maximum values on the y axis across different smoothings
   max_y_axis         = zeros(length(range_studies), 1);
   for smoothing_id   = [2 4]
      smoothing       = smoothings(smoothing_id);
      for study_id    = range_studies
         study        = studies{study_id};
         abbr         = studies_parameters.abbr{study_id};
         subject_1    = ['sub-' abbr '0001'];
         power_spectra_AFNI     = load([path_output study '/AFNI/smoothing_'     num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/power_spectra_one_subject.mat']);
         power_spectra_FSL      = load([path_output study '/FSL/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/power_spectra_one_subject.mat']);
         power_spectra_SPM      = load([path_output study '/SPM/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/power_spectra_one_subject.mat']);
         power_spectra_SPM_FAST = load([path_output study '/SPM_FAST/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/power_spectra_one_subject.mat']);
         power_spectra_AFNI     = power_spectra_AFNI.power_spectra_one_subject;
         power_spectra_FSL      = power_spectra_FSL.power_spectra_one_subject;
         power_spectra_SPM      = power_spectra_SPM.power_spectra_one_subject;
         power_spectra_SPM_FAST = power_spectra_SPM_FAST.power_spectra_one_subject;
         max_y_axis(study_id)   = max(vertcat(max_y_axis(study_id), power_spectra_AFNI, power_spectra_FSL, power_spectra_SPM, power_spectra_SPM_FAST));
      end
   end
   for smoothing_id   = [2 4]
      smoothing = smoothings(smoothing_id);
      study_id_plot   = 0;
      figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
      for study_id    = range_studies
         study        = studies{study_id};
         study_label  = studies_labels{study_id};
         TR           = studies_parameters.TR(study_id);
         abbr         = studies_parameters.abbr{study_id};
         subject_1    = ['sub-' abbr '0001'];
         power_spectra_AFNI     = load([path_output study '/AFNI/smoothing_'     num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/power_spectra_one_subject.mat']);
         power_spectra_FSL      = load([path_output study '/FSL/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/power_spectra_one_subject.mat']);
         power_spectra_SPM      = load([path_output study '/SPM/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/power_spectra_one_subject.mat']);
         power_spectra_SPM_FAST = load([path_output study '/SPM_FAST/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/power_spectra_one_subject.mat']);
         power_spectra_AFNI     = power_spectra_AFNI.power_spectra_one_subject;
         power_spectra_FSL      = power_spectra_FSL.power_spectra_one_subject;
         power_spectra_SPM      = power_spectra_SPM.power_spectra_one_subject;
         power_spectra_SPM_FAST = power_spectra_SPM_FAST.power_spectra_one_subject;
         f = linspace(0, 0.5/TR, 257);
         if any(strcmp(studies_out, study))
            continue;
         else
            study_id_plot = study_id_plot + 1;
            subplot(nrows, 2, study_id_plot);
            h1         = plot(f, power_spectra_AFNI(1:257),     'color', colors(1, :));       hold on;
            h2         = plot(f, power_spectra_FSL(1:257),      'color', colors(2, :));       hold on;
            h3         = plot(f, power_spectra_SPM(1:257),      'color', colors(3, :));       hold on;
            h32        = plot(f, power_spectra_SPM_FAST(1:257), 'color', colors(4, :));       hold on;
            h4         = plot(freq_studies_exp_id(study_id),    0,                    'k*');  hold on;
            h5         = plot(freq_studies_exp_id(study_id),    max_y_axis(study_id), 'k*');  hold on;
            h6         = plot(1/(2*str2num(exper_design(7:8))), 0,                    'c*');  hold on;
            h7         = plot(1/(2*str2num(exper_design(7:8))), max_y_axis(study_id), 'c*');  hold on;
            h80        = plot([0 0.5/TR], [1 1],                                      'k--'); hold on;
            if study_id_plot==9 || study_id_plot==10
               hx  = xlabel({' ', 'Frequency [Hz]', ' '});
            else
               hx  = xlabel('');
            end
            hy     = ylabel('Power spectra', 'Units', 'normalized');
            htitle = title(study_label, 'interpreter', 'none');
            xlim([0 0.5/TR]);
            ylim([0 max_y_axis(study_id)]);
            %-lowering vertical spacing between subplots
            pos    = get(gca, 'Position');
            pos(2) = pos(2)-0.023;
            set(gca, 'Position', pos);
            set([h1 h2 h3 h32 h80], 'LineWidth', 1.25);
            set(gca, 'XTick', linspace(0, 0.5/TR, 6));
            set(gca, 'XTickLabel', round(linspace(0, 0.5/TR, 6), 2));
            set(gca, 'FontSize', 7);
            set([hx hy htitle], 'FontSize', 7);
            %-controlling distance between y axis title and y axis
            hy_pos    = get(hy, 'Position');
            hy_pos(1) = -0.11;
            set(hy, 'Position', hy_pos);
         end
      end
      fig_ref = subplot(nrows, 2, nrows*2);
      plot(1);
      set(gca, 'visible', 'off');
      hlegend = legendflex([h1 h2 h3 h32 h80 h4 h6], {'AFNI', 'FSL', 'SPM', 'SPM with option FAST', 'Ideal power spectra', 'True design frequency', 'Assumed design frequency'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer',  [-260 -15], 'box', 'off', 'FontSize', 7, 'nrow', 4);
      set(hlegend, 'FontSize', 7);
      figname = [paper '_power_1st_subject_smoothing_' num2str(smoothing) '_exper_design_' exper_design];
      print_to_svg_to_pdf(figname, path_manage);
   end
end


%%%%%%%%%%%%%%%%%%%%%%%% POWER SPECTRA: TRUE DESIGNS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-finding maximum values on the y axis across different smoothings
max_y_axis         = zeros(length(range_studies), 1);
for smoothing_id   = [2 4]
   smoothing       = smoothings(smoothing_id);
   %-only for the boxcar-task-based datasets
   for study_id    = 7:10
      study        = studies{study_id};
      if exper_designs_exp_id(study_id)==100
         exper_design = 'boxcar10';
      else
         exper_design = exper_designs{exper_designs_exp_id(study_id)};
      end
      power_spectra_AFNI     = load([path_output study '/AFNI/smoothing_'     num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
      power_spectra_FSL      = load([path_output study '/FSL/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
      power_spectra_SPM      = load([path_output study '/SPM/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
      power_spectra_SPM_FAST = load([path_output study '/SPM_FAST/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
      power_spectra_AFNI     = power_spectra_AFNI.power_spectra;
      power_spectra_FSL      = power_spectra_FSL.power_spectra;
      power_spectra_SPM      = power_spectra_SPM.power_spectra;
      power_spectra_SPM_FAST = power_spectra_SPM_FAST.power_spectra;
      max_y_axis(study_id)   = max(vertcat(max_y_axis(study_id), power_spectra_AFNI, power_spectra_FSL, power_spectra_SPM));
   end
end
for smoothing_id   = [2 4]
   smoothing       = smoothings(smoothing_id);
   %-6 chosen so that the scaling of the subplots is the same as before
   study_id_plot   = 6;
   figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
   %-only for the boxcar-task-based datasets
   for study_id    = 7:10
      study        = studies{study_id};
      study_label  = studies_labels{study_id};
      TR           = studies_parameters.TR(study_id);
      if exper_designs_exp_id(study_id)==100
         exper_design = 'boxcar10';
      else
         exper_design = exper_designs{exper_designs_exp_id(study_id)};
      end
      power_spectra_AFNI     = load([path_output study '/AFNI/smoothing_'     num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
      power_spectra_FSL      = load([path_output study '/FSL/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
      power_spectra_SPM      = load([path_output study '/SPM/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
      power_spectra_SPM_FAST = load([path_output study '/SPM_FAST/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
      power_spectra_AFNI     = power_spectra_AFNI.power_spectra;
      power_spectra_FSL      = power_spectra_FSL.power_spectra;
      power_spectra_SPM      = power_spectra_SPM.power_spectra;
      power_spectra_SPM_FAST = power_spectra_SPM_FAST.power_spectra;
      f = linspace(0, 0.5/TR, 257);
      if any(strcmp(studies_out, study))
         continue;
      else
         study_id_plot = study_id_plot + 1;
         subplot(nrows, 2, study_id_plot);
         h1         = plot(f, power_spectra_AFNI(1:257),     'color', colors(1, :));       hold on;
         h2         = plot(f, power_spectra_FSL(1:257),      'color', colors(2, :));       hold on;
         h3         = plot(f, power_spectra_SPM(1:257),      'color', colors(3, :));       hold on;
         h32        = plot(f, power_spectra_SPM_FAST(1:257), 'color', colors(4, :));       hold on;
         h4         = plot(freq_studies_exp_id(study_id),    0,                    'k*');  hold on;
         h5         = plot(freq_studies_exp_id(study_id),    max_y_axis(study_id), 'k*');  hold on;
         h6         = plot(1/(2*str2num(exper_design(7:8))), 0,                    'c*');  hold on;
         h7         = plot(1/(2*str2num(exper_design(7:8))), max_y_axis(study_id), 'c*');  hold on;
         h80        = plot([0 0.5/TR], [1 1],                                      'k--'); hold on;
         if study_id_plot==9 || study_id_plot==10
            hx  = xlabel({' ', 'Frequency [Hz]', ' '});
         else
            hx  = xlabel('');
         end
         hy     = ylabel('Power spectra', 'Units', 'normalized');
         htitle = title(study_label, 'interpreter', 'none');
         xlim([0 0.5/TR]);
         ylim([0 max_y_axis(study_id)]);
         %-lowering vertical spacing between subplots
         pos    = get(gca, 'Position');
         pos(2) = pos(2)-0.023;
         set(gca, 'Position', pos);
         set([h1 h2 h3 h32 h80], 'LineWidth', 1.25);
         set(gca, 'XTick', linspace(0, 0.5/TR, 6));
         set(gca, 'XTickLabel', round(linspace(0, 0.5/TR, 6), 2));
         set(gca, 'FontSize', 7);
         set([hx hy htitle], 'FontSize', 7);
         %-controlling distance between y axis title and y axis
         hy_pos    = get(hy, 'Position');
         hy_pos(1) = -0.11;
         set(hy, 'Position', hy_pos);
      end
   end
   fig_ref = subplot(nrows, 2, nrows*2);
   plot(1);
   set(gca, 'visible', 'off');
   hlegend = legendflex([h1 h2 h3 h32 h80 h4 h6], {'AFNI', 'FSL', 'SPM', 'SPM with option FAST', 'Ideal power spectra', 'True design frequency', 'Assumed design frequency'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer',  [-260 -15], 'box', 'off', 'FontSize', 7, 'nrow', 4);
   set(hlegend, 'FontSize', 7);
   figname = [paper '_power_smoothing_' num2str(smoothing) '_true_designs'];
   print_to_svg_to_pdf(figname, path_manage);
end


%%%%%%%%%%%%%%%%%%%%%%%% SPATIAL DISTRIBUTION OF SIGNIFICANT VOXELS: SUBSET %%%%%%%%%%%%%%%%%%%%%%
for package_id  = range_packages
   package      = packages{package_id};
   study_id     = 11;
   smoothing    = 8;
   exper_design = 'event1';
   study        = studies_parameters.study{study_id};
   study_label  = studies_labels{study_id};
   abbr         = studies_parameters.abbr{study_id};
   no_subjects  = studies_parameters.n(study_id);
   %-altogether 91 axial slices (MNI 2mm isotropic), plotting 4 of them
   slices       = [20 37 54 71];
   figure();
   subject_1      = ['sub-' abbr '0001'];
   %-loading one mask, only to check the size
   data           = load([path_output study '/' package '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/cluster_binary_MNI.mat']);
   dims           = size(data.cluster_binary_MNI);
   sp_dist_joint  = zeros(4*dims(1), dims(2));
   sp_dist        = zeros(dims);
   for subject_id = 1:no_subjects
      subject                     = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
      cluster_binary_MNI_location = [path_output study '/' package '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject '/standardized_stats/cluster_binary_MNI.mat'];
      data                        = load(cluster_binary_MNI_location);
      sp_dist                     = sp_dist + data.cluster_binary_MNI;
   end
   sp_dist = rot90(sp_dist, 2);
   for slice_id = 1:length(slices)
      slice = slices(slice_id);
      sp_dist_joint((slice_id-1)*dims(1)+1:slice_id*dims(1), :) = sp_dist(:, :, slice);
   end
   imagesc(transpose(sp_dist_joint(:, :)/no_subjects*100), [0 30]);
   colormap gray; axis on; axis image; c = colorbar('FontSize', 11);
   title(study_label, 'interpreter', 'none', 'FontSize', 14);
   set(gca, 'xticklabel', [], 'yticklabel', [], 'xtick', [], 'ytick', []);
   figname = [paper '_dist_sm_' num2str(smoothing) '_' study '_' package];
   print_to_svg_to_pdf(figname, path_manage);
end


%%%%%%%%%%%%%%%%%%%%%%%% SPATIAL DISTRIBUTION OF SIGNIFICANT VOXELS: 4 COLUMNS %%%%%%%%%%%%%%%%%%%
for package_id = range_packages
   package     = packages{package_id};
   for smoothing_id = range_smoothings
      figure();
      smoothing        = smoothings(smoothing_id);
      study_id_plot    = 0;
      for study_id     = range_studies
         study         = studies_parameters.study{study_id};
         study_label   = studies_labels{study_id};
         abbr          = studies_parameters.abbr{study_id};
         no_subjects   = studies_parameters.n(study_id);
         if any(strcmp(studies_out, study))
            continue
         else
            study_id_plot   = study_id_plot + 1;
            clims           = [0 clims_studies(study_id)];
            subject_1       = ['sub-' abbr '0001'];
            %-loading one mask, only to check the size
            data            = load([path_output study '/' package '/smoothing_' num2str(smoothing) '/exper_design_' exper_designs_dist{1} '/HRF_' HRF_model '/' subject_1 '/standardized_stats/cluster_binary_MNI.mat']);
            dims            = size(data.cluster_binary_MNI);
            subplot(no_of_studies_for_dist, 1, study_id_plot);
            %-plotting the middle slice
            slice = round(dims(3)/2);
            load(['combined_results/sp_dist_joint_' package '_' num2str(smoothing) '_' study '.mat']);
            imagesc(transpose(sp_dist_joint(:, :, slice)), clims)
            colormap gray; axis on; axis image; c = colorbar('FontSize', 6);
            hold on;
            %-plotting red boxes around true experimental designs (only for task-based datasets)
            if strcmp('NKI_release_3_checkerboard_1400', study) || strcmp('NKI_release_3_checkerboard_645', study)
               col = 3;
            elseif strcmp('BMMR_checkerboard', study)
               col = 1;
            elseif strcmp('CRIC_checkerboard', study)
               col = 2;
            else
               col = 0;
            end
            if col > 0
               plot([(col-1)*dims(1)+2 (col-1)*dims(1)+2 col*dims(1)-1 col*dims(1)-1 (col-1)*dims(1)+2], [2 dims(2)-1 dims(2)-1 2 2], 'Color', 'r', 'LineStyle', '-', 'LineWidth', 1);
            end
            set(gca, 'xticklabel', [], 'yticklabel', [], 'xtick', [], 'ytick', []);
            if study_id == 10
               xlabel([exper_designs_dist{1} '        ' exper_designs_dist{2} '       ' exper_designs_dist{3} '        ' exper_designs_dist{4}], 'interpreter', 'none', 'FontSize', 6, 'fontweight', 'bold');
            end
            title([package ': ' study_label], 'interpreter', 'none', 'FontSize', 6);
            %-'Position': [left bottom width height]
            pos        = get(gca, 'Position');
            %-has to be adjusted if different number of plots, e.g. for 7 plots -0.033 works well; if nothing subtracted, 1st htitle is cut
            pos(2)     = pos(2)-0.023;
            pos_bar    = get(c, 'Position');
            pos_bar(1) = 0.75;
            %-2nd term changed, because of pos(2) change, 3rd and 4th terms fixed as otherwise the size of bars can vary...
            pos_bar    = [pos_bar(1) pos(2)-0.023+0.1 0.0224 0.0595];
            set(c,   'Position', pos_bar);
            set(gca, 'Position', [0.04 pos(2) 0.66 0.21]);
         end
      end
      set(gcf, 'units', 'inches', 'position', [0 0 4.0 ceil(no_of_studies_for_dist/7 * 7.5)]);
      figname = [paper '_dist_' package '_sm_' num2str(smoothing)];
      print_to_svg_to_pdf(figname, path_manage);
   end
end


%%%%%%%%%%%%%%%%%%%%%%%% BAR PLOTS: GROUP ANALYSES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
group_results_all                = readtable('combined_results/group_results_runs_with_sig_clusters.csv');
group_results_true               = group_results_all(group_results_all.NullData==0,:);
group_results_true               = group_results_true(:, [2 3 4 7]);
group_results_true.Pre_whitening = strtrim(group_results_true.Pre_whitening);
group_results_true.Dataset       = strtrim(group_results_true.Dataset);
group_results_true.Dataset       = strrep(group_results_true.Dataset, 'TASK: ', '');
group_results_true.Dataset       = strrep(group_results_true.Dataset, 'REST: ', '');
group_results_true.Dataset       = strrep(group_results_true.Dataset, ' (TR=1.97s)', '');
group_results_true.Dataset       = strrep(group_results_true.Dataset, ' (TR=3s)', '');
group_results_true.Dataset       = strrep(group_results_true.Dataset, '(TR=0.645s)', '0.645s');
group_results_true.Dataset       = strrep(group_results_true.Dataset, '(TR=1.4s)',   '1.4s');
group_results_true.Dataset       = strrep(group_results_true.Dataset, ' sensorimotor', '');
group_results_true.Dataset       = strrep(group_results_true.Dataset, ' checkerboard', '');
group_results_true.Properties.VariableNames(4) = cellstr('Avg_perc');
group_results_true.Avg_perc      = strrep(group_results_true.Avg_perc, '%', '');
group_results_true.Avg_perc      = str2double(group_results_true.Avg_perc);
group_results_true_random        = group_results_true(strcmp(group_results_true.GroupModel, 'random effects'), 2:4);
group_results_true_mixed         = group_results_true(strcmp(group_results_true.GroupModel, 'mixed effects'),  2:4);
group_datasets                   = categories(categorical(group_results_true.Dataset));
fig_size_group    = fig_size;
fig_size_group(4) = fig_size(4)/6;
figure('rend', 'painters', 'pos', fig_size_group, 'Visible', 'off');
for part = 1:2
   subplot(1, 2, part);
   pos_x_axis     = 0;
   for dataset_id = 1:length(group_datasets)
      dataset     = group_datasets{dataset_id};
      pos_x_axis  = pos_x_axis + 1;
      for package_id = range_packages
         package     = packages{package_id};
         pos_x_axis  = pos_x_axis + 1;
         if part == 1
            y_axis   = table2array(group_results_true_random(strcmp(group_results_true_random.Dataset, dataset) & strcmp(group_results_true_random.Pre_whitening, package), 3));
         else
            y_axis   = table2array(group_results_true_mixed (strcmp(group_results_true_mixed.Dataset,  dataset) & strcmp(group_results_true_mixed.Pre_whitening,  package), 3));
         end
         bar(pos_x_axis, y_axis, 'facecolor', colors(package_id, :)); hold on;
      end
   end
   xlim([0.8 pos_x_axis+1.2]);
   ylim([0 80]);
   hx = xlabel({' ', 'Dataset'},  'Units', 'normalized');
   hy = ylabel('% of significant voxels', 'Units', 'normalized');
   if part == 1
      htitle  = title('Group results for a random effects model', 'interpreter', 'none');
   else
      htitle  = title('Group results for a mixed effects model',  'interpreter', 'none');
   end
   %-controlling distance between y axis title and y axis
   hy_pos    = get(hy, 'Position');
   hy_pos(1) = -0.14;
   set(hy, 'Position', hy_pos);
   set(gca, 'XTick',      [3.5 8.5 13.5 18.5]);
   set([hx hy htitle], 'FontSize', 6);
   set(gca,            'FontSize', 6);
   set(gca, 'XTickLabel', group_datasets, 'FontSize', 6);
end
fig_ref = subplot(1, 2, 2);
hlegend = legendflex([h1 h2 h3 h32], {'AFNI', 'FSL', 'SPM', 'SPM with option FAST'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer',  [-120 18], 'box', 'off', 'FontSize', 6, 'nrow', 4);
figname = [paper '_group_results'];
print_to_svg_to_pdf(figname, path_manage);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EVENT-RELATED DESIGNS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-only for 'CamCAN_sensorimotor' dataset
study_id        = 11;
study           = studies{study_id};
study_label     = studies_labels{study_id};
smoothing       = 8;
smoothing_id    = 4;
designs_for_ERD = [1 16 17 18];
fig_size_ERD    = fig_size;
fig_size_ERD(4) = 950; 
figure('rend', 'painters', 'pos', fig_size_ERD, 'Visible', 'off');

%-POWER SPECTRA
subplot(14, 1, 1:2);
exper_design    = 'event1';
TR              = studies_parameters.TR(study_id);
power_spectra_AFNI     = load([path_output study '/AFNI/smoothing_'     num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
power_spectra_FSL      = load([path_output study '/FSL/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
power_spectra_SPM      = load([path_output study '/SPM/smoothing_'      num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
power_spectra_SPM_FAST = load([path_output study '/SPM_FAST/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
power_spectra_AFNI     = power_spectra_AFNI.power_spectra;
power_spectra_FSL      = power_spectra_FSL.power_spectra;
power_spectra_SPM      = power_spectra_SPM.power_spectra;
power_spectra_SPM_FAST = power_spectra_SPM_FAST.power_spectra;
max_y_axis = max([max(power_spectra_AFNI) max(power_spectra_FSL) max(power_spectra_SPM)]); %max(power_spectra_SPM_FAST)
f      = linspace(0, 0.5/TR, 257);
h1     = plot(f, power_spectra_AFNI(1:257),     'color', colors(1, :));      hold on;
h2     = plot(f, power_spectra_FSL(1:257),      'color', colors(2, :));      hold on;
h3     = plot(f, power_spectra_SPM(1:257),      'color', colors(3, :));      hold on;
h32    = plot(f, power_spectra_SPM_FAST(1:257), 'color', colors(4, :));      hold on;
h4     = plot(freq_studies_exp_id(study_id),    0,          'k*');           hold on;
h5     = plot(freq_studies_exp_id(study_id),    max_y_axis, 'k*');           hold on;
if ~strcmp(exper_design, 'event1') && ~strcmp(exper_design, 'event2')
   h60 = plot(1/(2*str2num(exper_design(7:8))), 0,          'c*');           hold on;
   h7  = plot(1/(2*str2num(exper_design(7:8))), max_y_axis, 'c*');           hold on;
end
h80    = plot([0 0.5/TR], [1 1], 'k--');                                     hold on;
hx     = xlabel({' ', 'Frequency [Hz]', ' '});
hy     = ylabel('Power spectra', 'Units', 'normalized');
htitle = title({study_label; ' '}, 'interpreter', 'none');
xlim([0 0.5/TR]);
ylim([0 max_y_axis]);
set([h1 h2 h3 h32 h80], 'LineWidth', 2);
set(gca, 'XTick', linspace(0, 0.5/TR, 6));
set(gca, 'XTickLabel', round(linspace(0, 0.5/TR, 6), 2));
set(gca, 'FontSize', 8);
set([hx hy], 'FontSize', 10);
set(htitle,  'FontSize', 12);
%-controlling distance between y axis title and y axis
set(hy, 'Units', 'Normalized', 'Position', [-0.1, 0.5, 0]);

%-MEAN PERCENTAGES
subplot(14, 1, 4:5);
x_axis     = 1 : length(designs_for_ERD);
for package_id = range_packages
   package = packages{package_id};
   y_axes  = 100*reshape(pos_fractions(package_id, study_id, smoothing_id, designs_for_ERD), [1, length(designs_for_ERD)]);
   h0      = plot([3 3], [0 1000000000], 'Color', [0.5 0.5 0.5]); hold on;
   h1      = plot(x_axis, y_axes(:), 'color', colors(package_id, :)); hold on;
   set(h1, 'LineWidth', 2);
end
set(h0, 'LineWidth', 1.5);
hx      = xlabel({' ', 'Assumed experimental design', ' '});
hy      = ylabel('Avg. % of sig voxels', 'Units', 'normalized');
max_y   = max(reshape(pos_fractions(:, study_id, smoothing_id, designs_for_ERD), [1, 4*length(designs_for_ERD)]));
xlim([0.8 length(designs_for_ERD)+0.2]);
ylim([0 100*max_y]);
set(gca, 'XTick', 1:length(designs_for_ERD));
set(gca, 'XTickLabel', repmat({'B1', 'B2', 'E1', 'E2'}, 1, 1));
set(gca, 'FontSize', 8);
ax = gca;
set([hx hy], 'FontSize', 10);
%-controlling distance between y axis title and y axis
set(hy, 'Units', 'Normalized', 'Position', [-0.1, 0.5, 0]);

%-POSITIVE RATES
subplot(14, 1, 7:8);
x_axis         = 1 : length(designs_for_ERD);
no_subjects    = studies_parameters.n(study_id);
for package_id = range_packages
   package = packages{package_id};
   sd      = sqrt(0.05*0.95/no_subjects)*1.96*100;
   y_axes  = [100*reshape(pos_rates(package_id, study_id, smoothing_id, designs_for_ERD), [1, length(designs_for_ERD)])];
   h0      = plot([3 3], [0 100], 'Color', [0.5 0.5 0.5]);            hold on;
   h1      = plot(x_axis, y_axes(:), 'color', colors(package_id, :)); hold on;
   set(h1, 'LineWidth', 2);
end
h5         = plot([0.5 length(designs_for_ERD)+0.5], [5 5],         'k');                         hold on;
h6         = plot([0.5 length(designs_for_ERD)+0.5], [5-sd 5-sd], '-.k', 'Color', [0.5 0.5 0.5]); hold on;
h7         = plot([0.5 length(designs_for_ERD)+0.5], [5+sd 5+sd], '-.k', 'Color', [0.5 0.5 0.5]); hold on;
h8         = plot(-10, -10, 'Color', [1 1 1]);      hold on;
h9         = plot(-10, -10, 'Color', [1 1 1]);      hold on;
h10        = plot(-10, -10, 'Color', [1 1 1]);      hold on;
h11        = plot(-10, -10, 'Color', [1 1 1]);      hold on;
h12        = plot(-10, -10, 'Color', [1 1 1]);      hold on;
h21        = plot(-10, -10, 'color', colors(1, :)); hold on;
h22        = plot(-10, -10, 'color', colors(2, :)); hold on;
h23        = plot(-10, -10, 'color', colors(3, :)); hold on;
h24        = plot(-10, -10, 'color', colors(4, :)); hold on;
hx         = xlabel({' ', 'Assumed experimental design', ' '});
hy         = ylabel('Positive rate (%)');
xlim([0.8 length(designs_for_ERD)+0.2]);
ylim([0 100]);
set(h5,                  'LineWidth', 2);
set([h0 h6 h7],          'LineWidth', 1.5);
set([h8 h9 h10 h11 h12], 'LineWidth', 0.000001);
set([h21 h22 h23 h24],   'LineWidth', 2);
set(gca, 'XTick', 1:length(designs_for_ERD));
set(gca, 'XTickLabel', repmat({'B1', 'B2', 'E1', 'E2'}, 1, 1));
set(gca, 'FontSize', 8);
set([hx hy], 'FontSize', 10);
%-controlling distance between y axis title and y axis
set(hy, 'Units', 'Normalized', 'Position', [-0.1, 0.5, 0]);

%-LEGEND
fig_ref = subplot(14, 1, 9:10);
plot(1);
set(gca, 'visible', 'off');
%-buffer values: first value down -> text to the left; second value down -> text down
hlegend = legendflex([h21 h22 h23 h24 h80 h0 h5 h6 h8 h9 h10 h11], {'AFNI', 'FSL', 'SPM', 'SPM with option FAST', 'Ideal power spectra', 'True experimental design', 'Expected for null data', '95% CI', sprintf('B1: \t boxcar 10s off + 10s on'), sprintf('B2: \t boxcar 40s off + 40s on'), sprintf('E1: \t subject-specific event-related design'), sprintf('E2: \t dummy event-related design')}, 'box', 'off', 'ref', fig_ref, 'buffer', [-40 -44], 'FontSize', 8, 'nrow', 6);

%-SPATIAL DISTRIBUTION OF SIGNIFICANT VOXELS
subplot(14, 1, 11:14);
exper_design   = 'event1';
abbr           = studies_parameters.abbr{study_id};
no_subjects    = studies_parameters.n(study_id);
subject_1      = ['sub-' abbr '0001'];
%-loading one mask, only to check the size
data           = load([path_output study '/AFNI/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/cluster_binary_MNI.mat']);
dims           = size(data.cluster_binary_MNI);
%-plotting the middle slice
slice          = round(dims(3)/2);
sp_dist_joint  = zeros(4*dims(1), dims(2));
for package_id = range_packages
   package     = packages{package_id};
   sp_dist     = zeros(dims);
   for subject_id = 1:no_subjects
      subject                     = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
      cluster_binary_MNI_location = [path_output study '/' package '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject '/standardized_stats/cluster_binary_MNI.mat'];
      data                        = load(cluster_binary_MNI_location);
      sp_dist                     = sp_dist + data.cluster_binary_MNI;
   end
   sp_dist = rot90(sp_dist, 2);
   sp_dist_joint((package_id-1)*dims(1)+1:package_id*dims(1), :) = sp_dist(:, :, slice);
end
imagesc(transpose(sp_dist_joint(:, :)/no_subjects*100), [0 70]);
colormap gray; axis on; axis image; c = colorbar('FontSize', 10);
title('Spatial distribution of significant clusters', 'interpreter', 'none', 'FontSize', 10);
xlabel('           AFNI                    FSL                     SPM             SPM with FAST', 'interpreter', 'none', 'FontSize', 10, 'fontweight', 'bold');
set(gca, 'xticklabel', [], 'yticklabel', [], 'xtick', [], 'ytick', []);

figname = [paper '_event_related'];
print_to_svg_to_pdf(figname, path_manage);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SLICE TIMING CORRECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-POWER SPECTRA
%-only for the 'CRIC_checkerboard' and 'CamCAN_sensorimotor' datasets
smoothing       = 8;
smoothing_id    = 4;
figure('rend', 'painters', 'pos', [0 0 2*300 550], 'Visible', 'off');
for study_id       = [10 11]
   study           = studies{study_id};
   study_label     = studies_labels{study_id};
   if strcmp(study, 'CRIC_checkerboard')
      exper_design = 'boxcar16';
   elseif strcmp(study, 'CamCAN_sensorimotor')
      exper_design = 'event1';
   end
   TR              = studies_parameters.TR(study_id);
   f               = linspace(0, 0.5/TR, 257);
   for package_id = 1:4
      if study_id == 10
         subplot(4, 2, (package_id-1)*2+1)
      else
         subplot(4, 2, (package_id-1)*2+2)
      end
      power_spectra     = load([path_output study '/' packages{package_id} '/smoothing_'     num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
      power_spectra     = power_spectra.power_spectra;
      power_spectra_stc = load([path_output study '/' packages{package_id} '/smoothing_'     num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '_slice_timing_correction/power_spectra.mat']);
      power_spectra_stc = power_spectra_stc.power_spectra;
      h1   = plot(f, power_spectra    (1:257),      'color', colors(package_id, :)); hold on;
      h2   = plot(f, power_spectra_stc(1:257), ':', 'color', colors(package_id, :)); hold on;
      h80  = plot([0 0.5/TR], [1 1], 'k--');                                         hold on;
      hy   = ylabel('Power spectra', 'Units', 'normalized');
      if package_id == 1
         htitle = title({study_label; ' '}, 'interpreter', 'none');
      else
         htitle = '';
      end
      if package_id == 4
         hx     = xlabel({' ', 'Frequency [Hz]', ' '});
      else
         hx     = xlabel('');
      end
      xlim([0 0.5/TR]);
      if strcmp(study, 'CRIC_checkerboard')
         ylim([0 2.15]);
      elseif strcmp(study, 'CamCAN_sensorimotor')
         ylim([0 1.75]);
      end
      set([h1 h2], 'LineWidth', 2);
      set(gca, 'XTick', linspace(0, 0.5/TR, 6));
      set(gca, 'XTickLabel', round(linspace(0, 0.5/TR, 6), 2));
      set(gca, 'FontSize', 8);
      set([hx hy], 'FontSize', 10);
      set(htitle,  'FontSize', 10);
      if study_id == 11
         legend(strrep(packages{package_id}, '_', ' '), strrep([packages{package_id} ' with slice timing correction'], '_', ' '), 'Location', 'southeast');
         legend boxoff;
      end
      %-controlling distance between y axis title and y axis
      set(hy, 'Units', 'Normalized', 'Position', [-0.1, 0.5, 0]);
   end
end
figname = [paper '_slice_timing_correction'];
print_to_svg_to_pdf(figname, path_manage);


%%%%%%%%%%%%%%%%%%%%%%%% QQ-PLOTS: 1ST SUBJECT IN EACH DATASET ONLY %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for smoothing_id = [2 4]
   smoothing     = smoothings(smoothing_id);
   study_id_plot = 0;
   figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
   for study_id  = range_studies
      study      = studies{study_id};
      if any(strcmp(studies_out, study))
         continue;
      else
         if study_id < 7
            exper_design = 'boxcar10';
         else
            exper_design = exper_designs{exper_designs_exp_id(study_id)};
         end
         disp([exper_design ' ' num2str(smoothing) ' ' study]);
         study_label     = studies_labels{study_id};
         abbr            = studies_parameters.abbr{study_id};
         subject_1       = ['sub-' abbr '0001'];
         study_id_plot   = study_id_plot + 1;
         subplot(nrows, 2, study_id_plot);
         for package_id  = 1:length(packages)
            package = packages{package_id};
            res4d   = niftiread([path_output study '/' package '/smoothing_'     num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/res4d_FSL_SPM_masked.nii.gz']);
            %-normalize the signal in each voxel separately
            res4d   = zscore(res4d, [], 4);
            res4d   = reshape(res4d, 1, []);
            res4d   = res4d(res4d~=0);
            res4d   = res4d(~isnan(res4d));
            res4d   = zscore(res4d);
            if     strcmp(package, 'AFNI')
               res4d_AFNI     = res4d;
            elseif strcmp(package, 'FSL')
               res4d_FSL      = res4d;
            elseif strcmp(package, 'SPM')
               res4d_SPM      = res4d;
            elseif strcmp(package, 'SPM_FAST')
               res4d_SPM_FAST = res4d;
            end
         end
         %-control random number generation
         rng(1);
         N_AFNI     = sort(normrnd(0, 1, [1 length(res4d_AFNI)]));
         N_FSL      = sort(normrnd(0, 1, [1 length(res4d_FSL)]));
         N_SPM      = sort(normrnd(0, 1, [1 length(res4d_SPM)]));
         N_SPM_FAST = sort(normrnd(0, 1, [1 length(res4d_SPM_FAST)]));
         h1     = plot(N_AFNI,     sort(res4d_AFNI),     'color', colors(1, :)); hold on;
         h2     = plot(N_FSL,      sort(res4d_FSL),      'color', colors(2, :)); hold on;
         h3     = plot(N_SPM,      sort(res4d_SPM),      'color', colors(3, :)); hold on;
         h32    = plot(N_SPM_FAST, sort(res4d_SPM_FAST), 'color', colors(4, :)); hold on;
         h4     = plot([-1000 1000], [-1000 1000],       'k--');                 hold on;
         if study_id_plot==9 || study_id_plot==10
            hx  = xlabel({' ', 'Normal theoretical quantiles', ' '});
         else
            hx  = xlabel('');
         end
         hy     = ylabel('Data quantiles', 'Units', 'normalized');
         htitle = title(study_label, 'interpreter', 'none');
         min_x  = min([N_AFNI N_FSL N_SPM N_SPM_FAST]);
         max_x  = max([N_AFNI N_FSL N_SPM N_SPM_FAST]);
         min_y  = min([min(res4d_AFNI) min(res4d_FSL) min(res4d_SPM) min(res4d_SPM_FAST)]);
         max_y  = max([max(res4d_AFNI) max(res4d_FSL) max(res4d_SPM) max(res4d_SPM_FAST)]);
         xlim([min_x max_x]);
         ylim([min_y max_y]);
         %-lowering vertical spacing between subplots
         pos    = get(gca, 'Position');
         pos(2) = pos(2)-0.023;
         set(gca, 'Position', pos);
         set([h1 h2 h3 h32 h4], 'LineWidth', 1.5);
         set(gca, 'FontSize', 7);
         set([hx hy htitle], 'FontSize', 7);
         %-controlling distance between y axis title and y axis
         hy_pos    = get(hy, 'Position');
         hy_pos(1) = -0.11;
         set(hy, 'Position', hy_pos);
      end
   end
   fig_ref = subplot(nrows, 2, nrows*2);
   plot(1);
   set(gca, 'visible', 'off');
   hlegend = legendflex([h1 h2 h3 h32 h4], {'AFNI', 'FSL', 'SPM', 'SPM with option FAST', 'Ideal fit with normal distribution'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer',  [-290 -15], 'box', 'off', 'FontSize', 7, 'nrow', 4);
   set(hlegend, 'FontSize', 7);
   figname = [paper '_qqplots_1st_subject_smoothing_' num2str(smoothing) '_exper_design_boxcar10_for_R_true_for_T'];
   print_to_svg_to_pdf(figname, path_manage);
end
