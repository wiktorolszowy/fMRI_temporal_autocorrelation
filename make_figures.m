

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   Figures comparing pre-whitening in AFNI/FSL/SPM.
%%%%   Written by:  Wiktor Olszowy, University of Cambridge
%%%%   Contact:     wo222@cam.ac.uk
%%%%   Created:     September 2016 - May 2018
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
colors                 = [0 1 0; 0 0 1; 1 0 0; 0.96 0.47 0.13];
studies_out            = cell.empty;
nrows                  = ceil((length(studies)-length(studies_out)+1)/2);
range_packages         = 1:length(packages);
range_studies          = 1:10; %-11th study (CamCAN) only for the last figure
range_exper_designs    = 1:16; %-17th and 18th designs only for the last figure
range_smoothings       = 1:length(smoothings);
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
for study_id = 1:length(studies)
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
      for study_id = range_studies
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
for exper_design_id = [1 16]
   exper_design     = exper_designs{exper_design_id};
   %-finding maximum values on the y axis across different smoothings
   max_y_axis       = zeros(length(range_studies), 1);
   for smoothing_id = [2 4]
      smoothing     = smoothings(smoothing_id);
      for study_id  = range_studies
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
      for study_id = range_studies
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


%%%%%%%%%%%%%%%%%%%%%%%% POWER SPECTRA: DIFFERENT DESIGNS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-finding maximum values on the y axis across different smoothings
max_y_axis         = zeros(length(range_studies), 1);
for smoothing_id   = [2 4]
   smoothing       = smoothings(smoothing_id);
   for study_id    = range_studies
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
   study_id_plot   = 0;
   figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
   for study_id = range_studies
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
   figname = [paper '_power_smoothing_' num2str(smoothing) '_different_designs'];
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
   pos_dist_joint = zeros(4*dims(1), dims(2));
   pos_dist       = zeros(dims);
   for subject_id = 1:no_subjects
      subject                     = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
      cluster_binary_MNI_location = [path_output study '/' package '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject '/standardized_stats/cluster_binary_MNI.mat'];
      data                        = load(cluster_binary_MNI_location);
      pos_dist                    = pos_dist + data.cluster_binary_MNI;
   end
   pos_dist = rot90(pos_dist, 2);
   for slice_id = 1:length(slices)
      slice = slices(slice_id);
      pos_dist_joint((slice_id-1)*dims(1)+1:slice_id*dims(1), :) = pos_dist(:, :, slice);
   end
   imagesc(transpose(pos_dist_joint(:, :)/no_subjects*100), [0 30]);
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
            pos_dist_joint  = zeros(length(exper_designs_dist)*dims(1), dims(2), dims(3));
            for exper_design_id = 1:length(exper_designs_dist)
               exper_design = exper_designs_dist{exper_design_id};
               pos_dist     = zeros(dims);
               %-it takes a while to make the spatial distribution plots; for resizing/checks one can uncomment the following 'if', so that only one row will be completely plotted
               %if study_id == no_of_studies_for_dist
                  for subject_id = 1:no_subjects
                     subject                     = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
                     cluster_binary_MNI_location = [path_output study '/' package '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject '/standardized_stats/cluster_binary_MNI.mat'];
                     if exist(cluster_binary_MNI_location, 'file') == 2
                        data     = load(cluster_binary_MNI_location);
                        pos_dist = pos_dist + data.cluster_binary_MNI;
                     %-for subjects 25 and 27 in 'NKI_release_3_RS_1400' no 'pos_dist's for 3 combinations of smoothing and experimental design (numerical problems), if no 'pos_dists' in a different case, say!
                     elseif ~(strcmp(study, 'NKI_release_3_RS_1400')==1 && (subject_id==25 || subject_id==27))
                        disp('problems with pos_dists!')
                     end
                  end
               %end
               pos_dist = rot90(pos_dist, 2);
               pos_dist_joint((exper_design_id-1)*dims(1)+1:exper_design_id*dims(1), :, :) = pos_dist;
            end
            subplot(no_of_studies_for_dist, 1, study_id_plot);
            %-plotting the middle slice
            slice = round(dims(3)/2);
            imagesc(transpose(pos_dist_joint(:, :, slice)/no_subjects*100), clims)
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EVENT-RELATED DESIGNS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%-only for 'CamCAN_sensorimotor' dataset
study_id        = 11;
study           = studies{study_id};
study_label     = studies_labels{study_id};
smoothing       = 8;
smoothing_id    = 4;
designs_for_ERD = [1 16 17 18];
%figure('rend', 'painters', 'pos', [0 0 150 40]);
figure();
figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');

%-POWER SPECTRA
subplot(4, 1, 1);
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
subplot(4, 1, 2);
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
subplot(4, 1, 3);
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
fig_ref = subplot(4, 1, 4);
plot(1);
set(gca, 'visible', 'off');
%~U(3,6)s off + ~U(1,4)s on
%-buffer values: first value down -> text to the left; second value down -> text down
hlegend = legendflex([h21 h22 h23 h24 h80 h0 h5 h6 h8 h9 h10 h11], {'AFNI', 'FSL', 'SPM', 'SPM with option FAST', 'Ideal power spectra', 'True experimental design', 'Expected for null data', '95% CI', sprintf('B1: \t boxcar 10s off + 10s on'), sprintf('B2: \t boxcar 40s off + 40s on'), sprintf('E1: \t subject-specific event-related design'), sprintf('E2: \t dummy event-related design')}, 'ref', fig_ref, 'anchor', [4 8], 'buffer', [-390 22], 'box', 'off', 'FontSize', 8, 'nrow', 6);
set(hlegend, 'FontSize', 10);
figname = [paper '_event_related'];
print_to_svg_to_pdf(figname, path_manage);

%-SPATIAL DISTRIBUTION OF SIGNIFICANT VOXELS FOR ERD: SAVED AS SEPARATE FIGURE
study_id     = 11;
smoothing    = 8;
exper_design = 'event1';
study        = studies_parameters.study{study_id};
study_label  = studies_labels{study_id};
abbr         = studies_parameters.abbr{study_id};
no_subjects  = studies_parameters.n(study_id);
figure();
subject_1      = ['sub-' abbr '0001'];
%-loading one mask, only to check the size
data           = load([path_output study '/AFNI/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject_1 '/standardized_stats/cluster_binary_MNI.mat']);
dims           = size(data.cluster_binary_MNI);
%-plotting the middle slice
slice          = round(dims(3)/2);
pos_dist_joint = zeros(4*dims(1), dims(2));
for package_id = range_packages
   package        = packages{package_id};
   pos_dist       = zeros(dims);
   for subject_id = 1:no_subjects
      subject                     = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
      cluster_binary_MNI_location = [path_output study '/' package '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject '/standardized_stats/cluster_binary_MNI.mat'];
      data                        = load(cluster_binary_MNI_location);
      pos_dist                    = pos_dist + data.cluster_binary_MNI;
   end
   pos_dist = rot90(pos_dist, 2);
   pos_dist_joint((package_id-1)*dims(1)+1:package_id*dims(1), :) = pos_dist(:, :, slice);
end
imagesc(transpose(pos_dist_joint(:, :)/no_subjects*100), [0 70]);
colormap gray; axis on; axis image; c = colorbar('FontSize', 11);
title('Spatial distribution of significant clusters', 'interpreter', 'none', 'FontSize', 14);
xlabel('          AFNI                   FSL                   SPM           SPM with FAST ', 'interpreter', 'none', 'FontSize', 11, 'fontweight', 'bold');
set(gca, 'xticklabel', [], 'yticklabel', [], 'xtick', [], 'ytick', []);
figname = [paper '_dist_sm_' num2str(smoothing) '_' study];
print_to_svg_to_pdf(figname, path_manage);
