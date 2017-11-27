

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%   Figures comparing different experimental designs (with different experimental
%%%%   frequencies) applied to different datasets.
%%%%   Written by:  Wiktor Olszowy, University of Cambridge
%%%%   Contact:     wo222@cam.ac.uk
%%%%   Created:     September-November 2016/17
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


paper                        = 'autocorr';
path_manage                  = fgetl(fopen('path_manage.txt'));
path_scratch                 = fgetl(fopen('path_scratch.txt'));
path_output                  = [path_scratch '/analysis_output_'];
studies_parameters           = readtable([path_manage '/studies_parameters.txt']);
studies                      = studies_parameters.study;
softwares                    = cellstr(['AFNI'; 'FSL '; 'SPM ']);
freq_cutoffs                 = cellstr(['different'; 'same     ']);
smoothings                   = [0 4 5 8];
exper_designs                = cellstr(['boxcar10'; 'boxcar12'; 'boxcar14'; 'boxcar16'; 'boxcar18'; 'boxcar20'; 'boxcar22'; 'boxcar24'; 'boxcar26'; 'boxcar28'; 'boxcar30'; 'boxcar32'; 'boxcar34'; 'boxcar36'; 'boxcar38'; 'boxcar40']);
fig_size                     = [0 0 550 655];
no_of_studies_for_dist       = 10;
clims_studies                = [2 2 10 10 20 20 20 2 20 2];
exper_designs_studies_exp_id = [100 100 100 100 6 6 2 100 4 100];
exper_designs_dist           = cellstr(['boxcar12'; 'boxcar16'; 'boxcar20'; 'boxcar30'; 'boxcar40']);
NumTicks                     = length(exper_designs);
colors                       = ['g'; 'b'; 'r'; 'c'];
studies_out                  = cell.empty;
nrows                        = ceil((length(studies)-length(studies_out)+1)/2);
range_softwares              = 1:length(softwares);
range_freq_cutoffs           = 1:length(freq_cutoffs);
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

%-only 1 HRF model!! 'gamma2_D'
combined                         = combined        (:,:,:,:,:,:);
pos_rates                        = pos_rates       (:,:,:,  :,:);
pos_mean_numbers                 = pos_mean_numbers(:,:,:,  :,:);
%-pmn stands for pos_mean_numbers
dims_pmn                         = size(pos_mean_numbers);
x_axis                           = range_exper_designs;
tmp_array                        = permute(pos_mean_numbers(:,:,:,:,range_exper_designs), [3 1 2 4 5]);
tmp_nrow                         = dims_pmn(3);
tmp_ncol                         = dims_pmn(1)*dims_pmn(2)*length(smoothings)*length(exper_designs)*1;
studies_mean_numbers_max         = max(reshape(tmp_array, tmp_nrow, tmp_ncol), [], 2);

studies_labels = studies;
for study_id = range_studies
   study       = studies{study_id};
   study_label = strrep(study, '_', ' ');
   study_label = strrep(study_label, '1400', 'TR=1.4s');
   study_label = strrep(study_label, '645',  'TR=0.645s');
   study_label = strrep(study_label, ' release 3',  '');
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
         y_axes = 100*reshape(pos_rates(1:length(softwares), 1:length(freq_cutoffs), study_id, smoothing_id, 1:length(exper_designs)), [3, 2, length(exper_designs)]);
         h0     = plot([exper_designs_studies_exp_id(study_id) exper_designs_studies_exp_id(study_id)], [0 100], 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
         h1     = plot(x_axis, squeeze(y_axes(1,2,:)), colors(1)); hold on;
         h3     = plot(x_axis, squeeze(y_axes(2,2,:)), colors(2)); hold on;
         h4     = plot(x_axis, squeeze(y_axes(2,1,:)), colors(2)); hold on;
         h5     = plot(x_axis, squeeze(y_axes(3,2,:)), colors(3)); hold on;
         h6     = plot(x_axis, squeeze(y_axes(3,1,:)), colors(3)); hold on;
         h15    = plot([0.5 NumTicks+0.5], [5 5], 'k'); hold on;
         h16    = plot([0.5 NumTicks+0.5], [5-sd 5-sd], '-.k', 'Color', [0.5 0.5 0.5]); hold on;
         h17    = plot([0.5 NumTicks+0.5], [5+sd 5+sd], '-.k', 'Color', [0.5 0.5 0.5]); hold on;
         h18    = plot(-10, -10, 'Color', [1 1 1]); hold on;
         h19    = plot(-10, -10, 'Color', [1 1 1]); hold on;
         h20    = plot(-10, -10, 'Color', [1 1 1]); hold on;
         h21    = plot(-10, -10, 'Color', [1 1 1]); hold on;
         h22    = plot(-10, -10, 'Color', [1 1 1]); hold on;
         h23    = plot(-10, -10, 'Color', [1 1 1]); hold on;
         h24    = plot(-10, -10, 'Color', [1 1 1]); hold on;
         hx     = xlabel(' ');
         hy     = ylabel('Positive rate (%)');
         htitle = title(study_label, 'interpreter', 'none');
         xlim([0.8 NumTicks+0.2]);
         ylim([0 100]);
         set([h4 h6], {'LineStyle'}, {':'});
         set([h1 h3 h4 h5 h6 h15],          {'LineWidth'}, {1.5});
         set([h16 h17],                     {'LineWidth'}, {1});
         set([h18 h19 h20 h21 h22 h23 h24], {'LineWidth'}, {0.000001});
         set(gca, 'XTick', 1:NumTicks);
         set(gca, 'XTickLabel', 10:2:40);
         set(gca, 'FontSize', 7);
         set([hx hy htitle], 'FontSize', 7);
      end
   end
   fig_ref = subplot(nrows, 2, nrows*2);
   plot(1);
   set(gca, 'visible', 'off');
   hlegend = legendflex([h1 h3 h4 h5 h6 h15 h16 h0], {'AFNI', 'FSL: 1/100', 'FSL: 1/(off+on times)', 'SPM: 1/128', 'SPM: 1/(10+off+on times)', 'Expected for null data', '95% CI', 'True experimental design'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer', [-180 10], 'box', 'off', 'FontSize', 7, 'nrow', 8);
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
         y_axes = reshape(pos_mean_numbers(1:length(softwares), 1:length(freq_cutoffs), study_id, smoothing_id, 1:length(exper_designs)), [3, 2, length(exper_designs)]);
         h0     = plot([exper_designs_studies_exp_id(study_id) exper_designs_studies_exp_id(study_id)], [0 1000000000], 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
         h1     = plot(x_axis, squeeze(y_axes(1,2,:)), colors(1)); hold on;
         h3     = plot(x_axis, squeeze(y_axes(2,2,:)), colors(2)); hold on;
         h4     = plot(x_axis, squeeze(y_axes(2,1,:)), colors(2)); hold on;
         h5     = plot(x_axis, squeeze(y_axes(3,2,:)), colors(3)); hold on;
         h6     = plot(x_axis, squeeze(y_axes(3,1,:)), colors(3)); hold on;
         hx     = xlabel(' ');
         hy     = ylabel('Mean #(sig vox)', 'Units', 'normalized');
         htitle = title(study_label, 'interpreter', 'none');
         xlim([0.8 NumTicks+0.2]);
         ylim([0 studies_mean_numbers_max(study_id)]);
         set([h4 h6],          {'LineStyle'}, {':'});
         set([h1 h3 h4 h5 h6], {'LineWidth'}, {1.5});
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
   hlegend = legendflex([h1 h3 h4 h5 h6 h0], {'AFNI', 'FSL: 1/100', 'FSL: 1/(off+on times)', 'SPM: 1/128', 'SPM: 1/(10+off+on times)', 'True experimental design'}, 'ref', fig_ref, 'anchor', [4 8], 'buffer', [-180 16], 'box', 'off', 'FontSize', 7, 'nrow', 6);
   set(hlegend, 'FontSize', 7);
   figname = [paper '_mean_numbers_smoothing_' num2str(smoothing)];
   print_to_svg_to_pdf(figname, path_manage);
end


%%%%%%%%%%%%%%%%%%%%%%%% LINE PLOTS: MEAN NUMBERS OF SIGNIFICANT VOXELS: SUBSET %%%%%%%%%%%%%%%%%%
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
   fig_size_subset(4)   = fig_size_subset(4)*nrows_subset/nrows;
   figure('rend', 'painters', 'pos', fig_size_subset, 'Visible', 'off');
   study_id_plot = 0;
   for study_id = range_studies_subset
      study         = studies{study_id};
      study_label   = studies_labels{study_id};
      if any(strcmp(studies_out, study))
         continue;
      else
         study_id_plot = study_id_plot + 1;
         subplot(nrows_subset, 2, study_id_plot);
         y_axes = reshape(pos_mean_numbers(1:length(softwares), 1:length(freq_cutoffs), study_id, smoothing_id, 1:length(exper_designs)), [3, 2, length(exper_designs)]);
         h0     = plot([exper_designs_studies_exp_id(study_id) exper_designs_studies_exp_id(study_id)], [0 1000000000], 'Color', [0.5 0.5 0.5], 'LineWidth', 1); hold on;
         h1     = plot(x_axis, squeeze(y_axes(1,2,:)), colors(1)); hold on;
         h3     = plot(x_axis, squeeze(y_axes(2,2,:)), colors(2)); hold on;
         h5     = plot(x_axis, squeeze(y_axes(3,2,:)), colors(3)); hold on;
         if study_id_plot==1
            hlegend = legendflex([h1 h3 h5], {'AFNI', 'FSL', 'SPM'}, 'anchor', [4 8], 'buffer', [-186 -2], 'box', 'off', 'FontSize', 7, 'nrow', 7);
            set(hlegend, 'FontSize', 7);
         end
         hx     = xlabel(' ');
         hy     = ylabel('Mean #(sig vox)', 'Units', 'normalized');
         htitle = title(study_label, 'interpreter', 'none');
         xlim([0.8 NumTicks+0.2]);
         ylim([0 studies_mean_numbers_max(study_id)]);
         set([h1 h3 h5], {'LineWidth'}, {1.5});
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
   figname = [paper '_mean_numbers_smoothing_' num2str(smoothing) '_' baseline '_subset'];
   print_to_svg_to_pdf(figname, path_manage);
end


%%%%%%%%%%%%%%%%%%%%%%%% SPATIAL DISTRIBUTION OF SIGNIFICANT VOXELS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
freq_cutoff  = 'same';
for software_id = range_softwares
   software  = softwares{software_id};
   HRF_model = 'gamma2_D';
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
         %-'FCP_Beijing' left due to limited space: these figures should fit in one column!
         if any(strcmp(studies_out, study))
            continue
         else
            study_id_plot = study_id_plot + 1;
            clims = [0 clims_studies(study_id)];
            cd(path_manage);
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
                     data = load([path_output study '/' software '/freq_cutoffs_' freq_cutoff '/smoothing_' num2str(smoothing) '/exper_design_' exper_design '/HRF_' HRF_model '/' subject '/standardized_stats/pos_mask_MNI.mat']);
                     pos_dist = pos_dist + data.pos_mask_MNI;
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
            title([study_label], 'interpreter', 'none', 'FontSize', 6);
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
