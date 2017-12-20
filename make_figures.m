

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   Figures comparing different experimental designs (with different experimental
%%%%   frequencies) applied to different datasets.
%%%%   Written by:  Wiktor Olszowy, University of Cambridge
%%%%   Contact:     wo222@cam.ac.uk
%%%%   Created:     September-December 2016/17
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


paper                        = 'autocorr';
path_manage                  = fgetl(fopen('path_manage.txt'));
path_scratch                 = fgetl(fopen('path_scratch.txt'));
path_output                  = [path_scratch '/analysis_output_'];
studies_parameters           = readtable([path_manage '/studies_parameters.txt']);
studies                      = studies_parameters.study;
softwares                    = cellstr(['AFNI'; 'FSL '; 'SPM ']);
smoothings                   = [0 4 5 8];
exper_designs                = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40']);
fig_size                     = [0 0 550 745];
no_of_studies_for_dist       = 10;
clims_studies                = [2 2 10 10 20 20 20 2 20 2];
exper_designs_studies_exp_id = [100 100 100 100 6 6 2 100 4 100];
freq_studies_exp_id          = [100 100 100 100 0.025 0.025 1/24 100 1/32 100];
exper_designs_dist           = cellstr(['boxcar12'; 'boxcar16'; 'boxcar20'; 'boxcar30'; 'boxcar40']);
HRF_model                    = 'gamma2_D';
freq_cutoff                  = 'same';
NumTicks                     = length(exper_designs);
colors                       = ['g'; 'b'; 'r'; 'c'];
studies_out                  = cell.empty;
nrows                        = ceil((length(studies)-length(studies_out)+1)/2);
range_softwares              = 1:length(softwares);
range_studies                = 1:length(studies);
range_exper_designs          = 1:length(exper_designs);
range_smoothings             = 1:length(smoothings);
baselines                    = cellstr(['rest'; 'task']);
studies_rest_subset          = [10 1 4 8];
studies_task_subset          = [5 6 7 9];

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
tmp_array                        = permute(pos_mean_numbers(:,:,:,:,range_exper_designs), [3 1 2 4 5]);
tmp_nrow                         = dims_pmn(3);
tmp_ncol                         = dims_pmn(1)*dims_pmn(2)*length(smoothings)*length(exper_designs)*1;
studies_mean_numbers_max         = max(reshape(tmp_array, tmp_nrow, tmp_ncol), [], 2);
tmp_array                        = permute(pos_fractions(:,:,:,:,range_exper_designs), [3 1 2 4 5]);
studies_mean_fractions_max       = max(reshape(tmp_array, tmp_nrow, tmp_ncol), [], 2);

studies_labels = studies;
for study_id = range_studies
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
   study_label = strrep(study_label, 'simulated using neuRosim', 'simulated using neuRosim TR=2s');
   study_label = strrep(study_label, 'TR', '(TR');
   study_label = [study_label ')'];
   studies_labels{study_id} = study_label;
end

for smoothing_id = range_smoothings
   smoothing = smoothings(smoothing_id);
   
   %%%%%%%%%%%%%%%%%%%%%%%% LINE PLOTS: POSITIVE RATES %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
   study_id_plot = 0;
   for study_id = range_studies
      study         = studies{study_id};
      study_label   = studies_labels{study_id};
      if any(strcmp(studies_out, study))
         continue;
      else
         study_id_plot = study_id_plot + 1;
         subplot(nrows, 2, study_id_plot);
         %-the following 2 is arbitrarily chosen, does not change anything
         sd     = sqrt(0.05*0.95/sum(combined(2, 2, study_id, :, 1)>-0.5))*1.96*100;
         %-1:2 remainder of different high-pass filters
         %-'100*' as percentages are used
         y_axes = 100*reshape(pos_rates(1:length(softwares), 1:2, study_id, smoothing_id, 1:length(exper_designs)), [3, 2, length(exper_designs)]);
         h0     = plot([exper_designs_studies_exp_id(study_id) exper_designs_studies_exp_id(study_id)], [0 100], 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
         h1     = plot(x_axis, squeeze(y_axes(1,2,:)), colors(1)); hold on;
         h2     = plot(x_axis, squeeze(y_axes(2,2,:)), colors(2)); hold on;
         h3     = plot(x_axis, squeeze(y_axes(3,2,:)), colors(3)); hold on;
         h15    = plot([0.5 NumTicks+0.5], [5 5], 'k'); hold on;
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
         set([h1 h2 h3 h15], {'LineWidth'}, {1.5});
         set([h16 h17],      {'LineWidth'}, {1});
         set(gca, 'XTick', 1:NumTicks);
         set(gca, 'XTickLabel', 10:2:40);
         set(gca, 'FontSize', 7);
         set([hx hy htitle], 'FontSize', 7);
      end
   end
   fig_ref = subplot(nrows, 2, nrows*2);
   plot(1);
   set(gca, 'visible', 'off');
   hlegend = legendflex([h1 h2 h3 h0 h15 h16], {'AFNI', 'FSL', 'SPM', 'True experimental design', 'Expected rate for null data', '95% confidence interval'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer', [-260 -5], 'box', 'off', 'FontSize', 7, 'nrow', 3);
   set(hlegend, 'FontSize', 7);
   figname = [paper '_rates_smoothing_' num2str(smoothing)];
   print_to_svg_to_pdf(figname, path_manage);
   
   %%%%%%%%%%%%%%%%%%%%%%%% LINE PLOTS: MEAN NUMBERS OF SIGNIFICANT VOXELS %%%%%%%%%%%%%%%%%%%%%%%%%%
   figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
   study_id_plot = 0;
   for study_id = range_studies
      study         = studies{study_id};
      study_label   = studies_labels{study_id};
      if any(strcmp(studies_out, study))
         continue;
      else
         study_id_plot = study_id_plot + 1;
         subplot(nrows, 2, study_id_plot);
         y_axes = reshape(pos_mean_numbers(1:length(softwares), 1:2, study_id, smoothing_id, 1:length(exper_designs)), [3, 2, length(exper_designs)]);
         h0     = plot([exper_designs_studies_exp_id(study_id) exper_designs_studies_exp_id(study_id)], [0 1000000000], 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
         h1     = plot(x_axis, squeeze(y_axes(1,2,:)), colors(1)); hold on;
         h2     = plot(x_axis, squeeze(y_axes(2,2,:)), colors(2)); hold on;
         h3     = plot(x_axis, squeeze(y_axes(3,2,:)), colors(3)); hold on;
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
         set([h1 h2 h3], {'LineWidth'}, {1.5});
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
   hlegend = legendflex([h1 h2 h3 h0], {'AFNI', 'FSL', 'SPM', 'True experimental design'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer', [-260 -5], 'box', 'off', 'FontSize', 7, 'nrow', 3);
   set(hlegend, 'FontSize', 7);
   figname = [paper '_mean_numbers_smoothing_' num2str(smoothing)];
   print_to_svg_to_pdf(figname, path_manage);

   %%%%%%%%%%%%%%%%%%%%%%%% LINE PLOTS: MEAN FRACTIONS OF SIGNIFICANT VOXELS %%%%%%%%%%%%%%%%%%%%%%%%
   figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
   study_id_plot = 0;
   for study_id = range_studies
      study         = studies{study_id};
      study_label   = studies_labels{study_id};
      if any(strcmp(studies_out, study))
         continue;
      else
         study_id_plot = study_id_plot + 1;
         subplot(nrows, 2, study_id_plot);
         %-'100*' as percentages are used
         y_axes = 100*reshape(pos_fractions(1:length(softwares), 1:2, study_id, smoothing_id, 1:length(exper_designs)), [3, 2, length(exper_designs)]);
         h0     = plot([exper_designs_studies_exp_id(study_id) exper_designs_studies_exp_id(study_id)], [0 1000000000], 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
         h1     = plot(x_axis, squeeze(y_axes(1,2,:)), colors(1)); hold on;
         h2     = plot(x_axis, squeeze(y_axes(2,2,:)), colors(2)); hold on;
         h3     = plot(x_axis, squeeze(y_axes(3,2,:)), colors(3)); hold on;
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
         set([h1 h2 h3], {'LineWidth'}, {1.5});
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
   hlegend = legendflex([h1 h2 h3 h0], {'AFNI', 'FSL', 'SPM', 'True experimental design'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer', [-260 -5], 'box', 'off', 'FontSize', 7, 'nrow', 3);
   set(hlegend, 'FontSize', 7);
   figname = [paper '_mean_fractions_smoothing_' num2str(smoothing)];
   print_to_svg_to_pdf(figname, path_manage);
end


%%%%%%%%%%%%%%%%%%%%%%%% LINE PLOTS: MEAN FRACTIONS OF SIGNIFICANT VOXELS: SUBSET %%%%%%%%%%%%%%%%
smoothing_id = 4;
smoothing    = smoothings(smoothing_id);
for baseline_id = 1:length(baselines)
   baseline = baselines{baseline_id};
   fig_size_subset = fig_size;
   if strcmp(baseline, 'rest')
      range_studies_subset = studies_rest_subset;
      nrows_subset         = ceil(length(studies_rest_subset)/2);
   else
      range_studies_subset = studies_task_subset;
      nrows_subset         = ceil(length(studies_task_subset)/2);
   end
   %-0.83 scaling used to make the figures in the main part a bit smaller
   fig_size_subset(4)   = 0.83*fig_size_subset(4)*(nrows_subset+1)/nrows;
   figure('rend', 'painters', 'pos', fig_size_subset, 'Visible', 'off');
   study_id_plot = 0;
   for study_id = range_studies_subset
      study         = studies{study_id};
      study_label   = studies_labels{study_id};
      study_id_plot = study_id_plot + 1;
      subplot(nrows_subset+1, 2, study_id_plot);
      %-'100*' as percentages are used
      y_axes = reshape(100*pos_fractions(1:length(softwares), 1:2, study_id, smoothing_id, 1:length(exper_designs)), [3, 2, length(exper_designs)]);
      h0     = plot([exper_designs_studies_exp_id(study_id) exper_designs_studies_exp_id(study_id)], [0 100], 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
      h1     = plot(x_axis, squeeze(y_axes(1,2,:)), colors(1)); hold on;
      h2     = plot(x_axis, squeeze(y_axes(2,2,:)), colors(2)); hold on;
      h3     = plot(x_axis, squeeze(y_axes(3,2,:)), colors(3)); hold on;
      if study_id_plot==3 || study_id_plot==4
         hx  = xlabel({' ', 'Assumed experimental design', ' '});
      else
         hx  = xlabel(' ');
      end
      %-without normalized units very difficult to change the position
      hy     = ylabel('Avg. % of sig voxels', 'Units', 'normalized');
      htitle = title(study_label, 'interpreter', 'none');
      %-controlling distance between y axis title and y axis
      hy_pos    = get(hy, 'Position');
      hy_pos(1) = -0.14;
      set(hy, 'Position', hy_pos);
      xlim([0.8 NumTicks+0.2]);
      ylim([0 100*studies_mean_fractions_max(study_id)]);
      %-lowering vertical spacing between subplots
      pos    = get(gca, 'Position');
      pos(2) = pos(2)-0.023;
      set(gca, 'Position', pos);
      set([h1 h2 h3], {'LineWidth'}, {1.5});
      set(gca, 'XTick', 1:NumTicks);
      set(gca, 'XTickLabel', 10:2:40);
      set(gca, 'FontSize', 7);
      set([hx hy htitle], 'FontSize', 7);
      if study_id_plot==1
         hlegend = legendflex([h1 h2 h3], {'AFNI', 'FSL', 'SPM'}, 'anchor', [4 8], 'buffer', [-186 -2], 'box', 'off', 'FontSize', 7, 'nrow', 7);
         set(hlegend, 'FontSize', 7);
      end
   end
   figname = [paper '_mean_fractions_smoothing_' num2str(smoothing) '_' baseline '_subset'];
   print_to_svg_to_pdf(figname, path_manage);
end


%%%%%%%%%%%%%%%%%%%%%%%% POWER SPECTRA %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for exper_design_id = [1 16]
   exper_design = exper_designs{exper_design_id};
   %-finding maximum values on the y axis across different smoothings
   max_y_axis   = zeros(length(studies), 1);
   for smoothing_id = [2 4]
      smoothing = smoothings(smoothing_id);
      for study_id = range_studies
         study        = studies{study_id};
         power_spectra_AFNI   = load([path_output study '/AFNI/freq_cutoffs_' freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_FSL    = load([path_output study '/FSL/freq_cutoffs_'  freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_SPM    = load([path_output study '/SPM/freq_cutoffs_'  freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_AFNI   = power_spectra_AFNI.power_spectra;
         power_spectra_FSL    = power_spectra_FSL.power_spectra;
         power_spectra_SPM    = power_spectra_SPM.power_spectra;
         max_y_axis(study_id) = max(vertcat(max_y_axis(study_id), power_spectra_AFNI, power_spectra_FSL, power_spectra_SPM));
      end
   end
   for smoothing_id = [2 4]
      smoothing = smoothings(smoothing_id);
      study_id_plot   = 0;
      figure('rend', 'painters', 'pos', fig_size, 'Visible', 'off');
      for study_id = range_studies
         study        = studies{study_id};
         study_label  = studies_labels{study_id};
         TR           = studies_parameters.TR(study_id);
         power_spectra_AFNI = load([path_output study '/AFNI/freq_cutoffs_' freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_FSL  = load([path_output study '/FSL/freq_cutoffs_'  freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_SPM  = load([path_output study '/SPM/freq_cutoffs_'  freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
         power_spectra_AFNI = power_spectra_AFNI.power_spectra;
         power_spectra_FSL  = power_spectra_FSL.power_spectra;
         power_spectra_SPM  = power_spectra_SPM.power_spectra;
         f = linspace(0, 0.5/TR, 257);
         if any(strcmp(studies_out, study))
            continue;
         else
            study_id_plot = study_id_plot + 1;
            subplot(nrows, 2, study_id_plot);
            h1         = plot(f, power_spectra_AFNI(1:257), colors(1)); hold on;
            h2         = plot(f, power_spectra_FSL(1:257),  colors(2)); hold on;
            h3         = plot(f, power_spectra_SPM(1:257),  colors(3)); hold on;
            h4         = plot(freq_studies_exp_id(study_id),    0,                    'k*'); hold on;
            h5         = plot(freq_studies_exp_id(study_id),    max_y_axis(study_id), 'k*'); hold on;
            h6         = plot(1/(2*str2num(exper_design(7:8))), 0,                    'c*'); hold on;
            h7         = plot(1/(2*str2num(exper_design(7:8))), max_y_axis(study_id), 'c*'); hold on;
            %h8        = plot(1/100,                            0,                    'm*'); hold on;
            %h9        = plot(1/100,                            max_y_axis(study_id), 'm*'); hold on;
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
            set([h1 h2 h3], {'LineWidth'}, {1.25});
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
      hlegend = legendflex([h1 h2 h3 h4 h6], {'AFNI', 'FSL', 'SPM', 'True design frequency', 'Assumed design frequency'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer',  [-260 -5], 'box', 'off', 'FontSize', 7, 'nrow', 3);
      set(hlegend, 'FontSize', 7);
      figname = [paper '_power_smoothing_' num2str(smoothing) '_exper_design_' exper_design];
      print_to_svg_to_pdf(figname, path_manage);
   end
end


%%%%%%%%%%%%%%%%%%%%%%%% POWER SPECTRA: SUBSET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
study_id       = 4;
smoothing      = 8;
exper_design   = 'boxcar36';
study          = studies{study_id};
study_label    = studies_labels{study_id};
TR             = studies_parameters.TR(study_id);
fig_size_small    = fig_size;
fig_size_small(3) = fig_size_small(3)/2;
fig_size_small(4) = fig_size_small(4)/5;
figure('rend', 'painters', 'pos', fig_size_small, 'Visible', 'off');
power_spectra_AFNI = load([path_output study '/AFNI/freq_cutoffs_' freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
power_spectra_FSL  = load([path_output study '/FSL/freq_cutoffs_'  freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
power_spectra_SPM  = load([path_output study '/SPM/freq_cutoffs_'  freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/power_spectra.mat']);
power_spectra_AFNI = power_spectra_AFNI.power_spectra;
power_spectra_FSL  = power_spectra_FSL.power_spectra;
power_spectra_SPM  = power_spectra_SPM.power_spectra;
f      = linspace(0, 0.5/TR, 257);
h1     = plot(f, power_spectra_AFNI(1:257), colors(1)); hold on;
h2     = plot(f, power_spectra_FSL(1:257),  colors(2)); hold on;
h3     = plot(f, power_spectra_SPM(1:257),  colors(3)); hold on;
hx     = xlabel({' ', 'Frequency [Hz]', ' '});
hy     = ylabel('Power spectra', 'Units', 'normalized');
htitle = title(study_label, 'interpreter', 'none');
xlim([0 0.5/TR]);
%ylim([0 0.05]);
set([h1 h2 h3], {'LineWidth'}, {1.5});
set(gca, 'XTick', linspace(0, 0.5/TR, 6));
set(gca, 'XTickLabel', round(linspace(0, 0.5/TR, 6), 2));
set(gca, 'FontSize', 8);
set([hx hy htitle], 'FontSize', 8);
%-controlling distance between y axis title and y axis
hy_pos    = get(hy, 'Position');
hy_pos(1) = -0.11;
set(hy, 'Position', hy_pos);
hlegend = legendflex([h1 h2 h3], {'AFNI', 'FSL', 'SPM'}, 'anchor', [4 8], 'buffer', [-63 5], 'box', 'off', 'FontSize', 7, 'nrow', 7);
set(hlegend, 'FontSize', 7);
figname = [paper '_power_1dataset_smoothing_' num2str(smoothing) '_exper_design_' exper_design];
print_to_svg_to_pdf(figname, path_manage);


%%%%%%%%%%%%%%%%%%%%%%%% SPATIAL DISTRIBUTION OF SIGNIFICANT VOXELS: SUBSET %%%%%%%%%%%%%%%%%%%%%%
software     = 'SPM';
study_id     = 4;
smoothing    = 8;
exper_design = 'boxcar36';
study        = studies_parameters.study{study_id};
study_label  = studies_labels{study_id};
abbr         = studies_parameters.abbr{study_id};
task         = studies_parameters.task{study_id};
no_subjects  = studies_parameters.n(study_id);
%-altogether 91 axial slices (MNI 2mm isotropic), plotting 4 of them
slices       = [20 37 54 71];
figure();
subject_1 = ['sub-' abbr '0001'];
%-loading one mask, only to check the size
data      = load([path_output study '/' software '/freq_cutoffs_' freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_designs_dist{1} '/HRF_' HRF_model '/' subject_1 '/standardized_stats/pos_mask_MNI.mat']);
dims      = size(data.pos_mask_MNI);
pos_dist_joint = zeros(4*dims(1), dims(2));
pos_dist = zeros(dims);
for subject_id = 1:no_subjects
   subject = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
   pos_mask_location = [path_output study '/' software '/freq_cutoffs_' freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject '/standardized_stats/pos_mask_MNI.mat'];
   data = load(pos_mask_location);
   pos_dist = pos_dist + data.pos_mask_MNI;
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
figname = [paper '_dist_worst_' software '_sm_' num2str(smoothing)];
print_to_svg_to_pdf(figname, path_manage);


%%%%%%%%%%%%%%%%%%%%%%%% SPATIAL DISTRIBUTION OF SIGNIFICANT VOXELS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for software_id = range_softwares
   software  = softwares{software_id};
   parfor smoothing_id = range_smoothings
      figure();
      smoothing = smoothings(smoothing_id);
      study_id_plot = 0;
      for study_id = range_studies
         study         = studies_parameters.study{study_id};
         study_label   = studies_labels{study_id};
         abbr          = studies_parameters.abbr{study_id};
         task          = studies_parameters.task{study_id};
         no_subjects   = studies_parameters.n(study_id);
         if any(strcmp(studies_out, study))
            continue
         else
            study_id_plot = study_id_plot + 1;
            clims = [0 clims_studies(study_id)];
            subject_1 = ['sub-' abbr '0001'];
            %-loading one mask, only to check the size
            data      = load([path_output study '/' software '/freq_cutoffs_' freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_designs_dist{1} '/HRF_' HRF_model '/' subject_1 '/standardized_stats/pos_mask_MNI.mat']);
            dims      = size(data.pos_mask_MNI);
            pos_dist_joint = zeros(length(exper_designs_dist)*dims(1), dims(2), dims(3));
            for exper_design_id = 1:length(exper_designs_dist)
               exper_design = exper_designs_dist{exper_design_id};
               pos_dist = zeros(dims);
               %-it takes a while to make the spatial distribution plots; for resizing/checks one can uncomment the following 'if', so that only one row will be completely plotted.
               %if study_id == no_of_studies_for_dist
                  for subject_id = 1:no_subjects
                     subject = ['sub-' abbr repmat('0', 1, 4-length(num2str(subject_id))) num2str(subject_id)];
                     pos_mask_location = [path_output study '/' software '/freq_cutoffs_' freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject '/standardized_stats/pos_mask_MNI.mat'];
                     if exist(pos_mask_location, 'file') == 2
                        data = load(pos_mask_location);
                        pos_dist = pos_dist + data.pos_mask_MNI;
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
            if col>0
               plot([(col-1)*dims(1)+2 (col-1)*dims(1)+2 col*dims(1)-1 col*dims(1)-1 (col-1)*dims(1)+2], [2 dims(2)-1 dims(2)-1 2 2], 'Color', 'r', 'LineStyle', '-', 'LineWidth', 1);
            end
            set(gca, 'xticklabel', [], 'yticklabel', [], 'xtick', [], 'ytick', []);
            if study_id == length(studies)
               xlabel([exper_designs_dist{1} '        ' exper_designs_dist{2} '       ' exper_designs_dist{3} '        ' exper_designs_dist{4} '        ' exper_designs_dist{5}], 'interpreter', 'none', 'FontSize', 6, 'fontweight', 'bold');
            end
            title(study_label, 'interpreter', 'none', 'FontSize', 6);
            pos        = get(gca, 'Position');
            %-has to be adjusted if different number of plots, e.g. for 7 plots -0.033 works well
            pos(2)     = pos(2)-0.023;
            pos_bar    = get(c, 'Position');
            pos_bar(1) = 0.91;
            %-last term there, because this value used to calculate pos(2)
            pos_bar(2) = pos_bar(2)+0.075-0.023;
            set(c,   'Position', pos_bar);
            set(gca, 'Position', [0.04 pos(2) 0.83 0.21]);
         end
      end
      set(gcf, 'units', 'inches', 'position', [0 0 4.0 ceil(no_of_studies_for_dist/7 * 7.5)]);
      figname = [paper '_dist_' software '_sm_' num2str(smoothing)];
      print_to_svg_to_pdf(figname, path_manage);
   end
end
