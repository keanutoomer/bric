function MARSBAR_script_RPE
% MarsBaR batch script
%
% Niamh C (April 2025), Nadege B (April 2008), largely cannibalized from
% run_tutorial in the example marsbar data set (batch directory) by matthewbrett
% See http://marsbar.sourceforge.net
% Edited by Keanu Toomer (Nov 2025)

%% changed by user
Basedir = '/media/STUDY-HP-LloH-HV-010622/03_derivatives/spm-stats/';
Model = 'model-factorial_with_motor';

% path to directory containing subjects' models estimation results. 
model_path = fullfile(Basedir, Model, 'first_level');

% random effect path:
ROI_path = fullfile(Basedir, Model, 'group_level', 'ROIs');
ROI_names = {'model_1_ibNIB_23_-44_-15_roi.mat'};           %if using all ROI contained in ROI_path, type ROI_files='inf'

% subject list. If not specified, folder names will be read from
% subjects_dir.

% Participants to manually include/exclude - leave blank to read all
include = [];
exclude = ['sub-mueh0210']; % <- pilot data subjects = ['sub-jnsu0132'; 'sub-lzdv1218'; 'sub-pttr0360'], log file error subject = ['sub-mueh0210']
% Get subject IDs
if ~isempty(include)
    sub_names = select_IDs(include, [], exclude);
else
    sub_names = select_IDs(model_path, 'sub-*', exclude);
end
fprintf('%d participants identified\n', numel(sub_names));

exclude_subjects = {}; % participants can be excluded by specifing their ID 

% folder where to save marsbar reconfigured design
Est_path = fullfile(Basedir, Model, 'ROI_analysis');
% folder where to save results, time course...
Res_path = fullfile(Basedir, Model, 'ROI_results');

% Regressors for which we wants stats and stuffs, not used in the script
% for now. see line 171
% Ic = [1 3 5];

% Event settings
together = 1;  % 0 for no, 1 for averaging across the same events
event_duration = 0;  % Default event duration (in seconds)
time_course = 'Fitted';  % Options: 'FIR' or 'Fitted'

% For FIR time course only: Length of FIR in seconds
fir_length = 20;
opts = struct('percent', 1);  % Percent signal change

% Plot results?
plot_res = 1;

% Define events and their corresponding labels
events = {'Idealised - Like', 'Idealised - Next', 'Non-idealised - Like', 'Non-idealised - Next'};
event_labels = {'[-1 -0.5]', '[-0.5 0]', '[0 0.5]', '[0.5 1]'};

% Add MarsBaR script folder to the path
addpath(genpath('/home/Researcher/marsbar-0.44'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MarsBaR Setup
% Check MarsBaR version
if isempty(which('marsbar'))
    error('Need MarsBaR on the path');
end
v = str2num(marsbar('ver')); %#ok<ST2NM>
if v < 0.35
    error('Batch script only works for MarsBaR >= 0.35');
end
marsbar('on');  % Enable MarsBaR

% Set SPM defaults
spm('defaults', 'fmri');

%% Define ROIs to be estimated
if strcmp(ROI_names, 'inf')
    roi_list = dir(fullfile(ROI_path, '*roi.mat'));
    ROI_names = {roi_list.name}';
    if isempty(roi_list), disp('No ROI file in ROI folder'), end
end

% Load ROIs
for i = 1:numel(ROI_names)
    ROI_array{i} = maroi(fullfile(ROI_path, ROI_names{i}));
end

%% Get participants' IDs
if ~exist('sub_names', 'var') || isempty(sub_names)
    sub_names = cellstr(ls(model_path));
    sub_names = sub_names(3:end);
    if ~isempty(exclude_subjects)
        for excl = 1:length(exclude_subjects)
            excl_idx = strmatch(exclude_subjects{excl}, sub_names); %#ok<MATCH2>
            sub_names(excl_idx) = [];
        end
    end
    sub_names = sortstrnum(sub_names);
end

%% Main processing loop for all subjects and ROIs
for subject = 1:numel(sub_names)
    model_dir = fullfile(model_path, sub_names{subject});
    disp(model_dir);

    clear model_file
    model_file = fullfile(model_dir, 'SPM.mat');
    Est_dir = fullfile(Est_path, sub_names{subject});

    % Create analysis directory if it doesn't exist
    if ~exist(Est_dir, 'dir')
        mkdir(Est_dir);
    end

    for roi_no = 1:length(ROI_array)  % Loop through ROIs
        roi = ROI_array{roi_no};

        % If file already exists, load the MarsBaR object
        if exist(fullfile(Est_dir, ['mars_' label(ROI_array{roi_no}) '.mat']), 'file')
            load(fullfile(Est_dir, ['mars_' label(ROI_array{roi_no}) '.mat']));
        else
            % Create MarsBaR design object
            D = mardo(model_file);
            if ~is_spm_estimated(D)
                error('Model has not been estimated by SPM.');
            end

            % Extract data
            Y = get_marsy(roi, D, 'mean');
            sumY = summary_data(Y);

            % Estimate the model
            E = estimate(D, Y);

            % Import contrasts
            if has_contrasts(D)
                xCon = get_contrasts(D);
                E = set_contrasts(E, xCon);  % Set contrasts in the design object
            end

            save_spm(E, fullfile(Est_dir, ['SPM_' label(ROI_array{roi_no})]));
            save(fullfile(Est_dir, ['mars_' label(ROI_array{roi_no})]), 'E', 'Y', 'sumY');
        end

        b = betas(E);

        if together == 1
            ets = event_types_named(E);
            event_spec = {ets.e_spec};
            event_names = {ets.name};
            n_event_types = length(ets);
        else
            [event_spec, event_names] = event_spects(E);
            n_event_types = size(event_spec, 2);
        end

        if subject == 1
            Data(roi_no).roi_name = ROI_names{roi_no};
            Data(roi_no).beta = NaN(numel(sub_names), size(b', 2));
        end

        Data(roi_no).beta(subject, 1:size(b', 2)) = b';
        if size(Data(roi_no).beta, 2) > size(b, 1)
            Data(roi_no).beta(subject, size(b, 1) + 1:end) = NaN;
        end
        Data(roi_no).summary_time_course(subject, 1:size(sumY, 1)) = sumY';
        if size(Data(roi_no).summary_time_course, 2) > size(sumY, 1)
            Data(roi_no).summary_time_course(subject, size(sumY, 1) + 1:end) = NaN;
        end

        %% Time course and percent signal change
        if strcmp('Fitted', time_course)
            for i = 1:n_event_types
                % Fitted time courses
                [tc{i}, dt(i)] = event_fitted(E, event_spec{i}, event_duration);
                tc{i} = tc{i} / block_means(E) * 100;  % Convert to % signal change
                psc = event_signal(E, event_spec{i}, event_duration);

                % Store results across all subjects
                if subject == 1
                    TC(roi_no, i).roi_name = label(ROI_array{roi_no});
                    TC(roi_no, i).event_name = event_names{i};
                    TC(roi_no, i).values(subject, :) = sum(tc{1, i}, 2);
                    TC(roi_no, i).time(subject, :) = dt(i);
                    PSC(roi_no).roi_name = label(ROI_array{roi_no});
                    PSC(roi_no).event_name = event_names;
                    PSC(roi_no).values(subject, i) = psc;
                else
                    idx = find(strcmp(event_names{i}, {TC(1, :).event_name}));
                    if ~isempty(idx)
                        TC(roi_no, idx).values(subject, :) = sum(tc{1, i}, 2);
                    else
                        TC(roi_no, size(TC, 2) + 1).values(subject, :) = sum(tc{1, i}, 2);
                        TC(roi_no, size(TC, 2) + 1).time(subject, :) = dt(i);
                    end
                    PSC(roi_no).values(subject, i) = psc;
                end
            end

        elseif strcmp('FIR', time_course)
            % FIR time course analysis
            bin_length = tr(E);
            bin_no = fir_length / bin_length;

            for i = 1:n_event_types
                tc{i} = event_fitted_fir(E, event_spec{i}, bin_length, bin_no, opts);
                psc = event_signal(E, event_spec{i}, event_duration);

                if subject == 1
                    TC(roi_no, i).roi_name = label(ROI_array{roi_no});
                    TC(roi_no, i).event_name = event_names{i};
                    TC(roi_no, i).values(subject, :) = tc{1, i};
                    PSC(roi_no).roi_name = label(ROI_array{roi_no});
                    PSC(roi_no).event_name = event_names;
                    PSC(roi_no).values(subject, :) = psc;
                else
                    idx = find(strcmp(event_names{i}, {TC(1, :).event_name}));
                    if ~isempty(idx)
                        TC(roi_no, idx).values(subject, :) = tc{1, i};
                    else
                        TC(roi_no, size(TC, 2) + 1).values(subject, :) = tc{1, i};
                    end
                    PSC(roi_no).values(subject, i) = psc;
                end
            end
        end
    end
end

%% Save results and summaries
save(fullfile(Res_path, 'roi_data.mat'), 'TC', 'PSC', 'Data');

%% Plot PSC bar plots for selected events only

% % Create result directory if it doesnt exist
% if ~exist(Res_path, 'dir')
%     mkdir(Res_path);
% end
% 
% for roi_no = 1:length(PSC)
% 
%     % Get mean PSC across subjects
%     mean_psc = nanmean(PSC(roi_no).values, 1);
% 
%     % Match events of interest to PSC event names
%     [is_member, event_idx] = ismember(events, PSC(roi_no).event_name);
% 
%     % Check for mismatches
%     if any(~is_member)
%         error('One or more specified events not found in PSC(%d).event_name.', roi_no);
%     end
% 
%     % Subset mean_psc to only include events of interest
%     mean_psc_subset = mean_psc(event_idx);
% 
%     % Create bar plot
%     figure('Name', PSC(roi_no).roi_name, 'Color', 'w');
%     bar(mean_psc_subset, 'FaceColor', [0.3 0.5 0.8]);
% 
%     % Format axes and labels
%     set(gca, 'XTickLabel', event_labels, 'XTick', 1:length(event_labels));
%     ylabel('% Signal Change');
%     title(strrep(PSC(roi_no).roi_name, '_', '\_'));
% 
%     % Enable grid for better visualization
%     grid on;
% 
%     % Save plot
%     save_path = fullfile(Res_path, [PSC(roi_no).roi_name(1:end-4) '_R_Caud_PSC_barplot.png']);
%     saveas(gcf, save_path);
% 
%     % Close figure to prevent overlap
%     close(gcf);
% 
% end

% % Loop through each ROI and plot
% for roi = 1:length(PSC)
% 
%     % Preallocate
%     average = zeros(1, length(events));
%     se = zeros(1, length(events));
% 
%     for ev = 1:length(events)
%         idx = find(strcmp(PSC(roi).event_name, events{ev}));
%         values = PSC(roi).values(:, idx);
%         average(ev) = mean(values);
%         se(ev) = std(values) / sqrt(length(values)); % Standard error
%     end
% 
%     % Plot
%     figure('Color',[1 1 1])
%     errorbar(1:length(events), average, se, '-o', 'LineWidth', 1.5, 'MarkerSize', 8);
%     set(gca, 'XTick', 1:length(events), 'XTickLabel', events, 'FontSize', 12);
%     xlabel('Events');
%     ylabel('Percent Signal Change');
% 
%     title(strrep(PSC(roi).roi_name, '_', ' '), 'FontWeight','bold', 'FontSize',14);
%     grid on;
% 
%     % Optional: save plot
%     saveas(gcf, fullfile(Res_path, [PSC(roi).roi_name '_PSC_line_plot.png']));
% end

% Loop through each ROI and plot
for roi = 1:length(PSC)

    % Preallocate
    average = zeros(1, length(events));
    se = zeros(1, length(events));

    for ev = 1:length(events)
        idx = find(strcmp(PSC(roi).event_name, events{ev}));
        values = PSC(roi).values(:, idx);
        average(ev) = mean(values);
        se(ev) = std(values) / sqrt(length(values)); % Standard error
    end

   % Plot
    figure('Color',[1 1 1])

    % Plot only the points with error bars (no connecting line)
    h = errorbar(1:length(events), average, se, 'o', ...
        'LineWidth', 1.5, 'MarkerSize', 8, 'Color', [0 0 0]); 
    hold on;

    % Fill the circles (marker face color)
    set(h, 'MarkerFaceColor', [0.0039 0.0039 0.4510]); 

    % Fit and plot solid line of best fit
    x = 1:length(events);
    p = polyfit(x, average, 1);  % Linear fit
    y_fit = polyval(p, x);
    plot(x, y_fit, '-', 'Color', [0 0 0], 'LineWidth', 1.5); % Solid black line

    % Axis labels and formatting
    set(gca, 'XTick', 1:length(event_labels), 'XTickLabel', event_labels, 'FontSize', 12);
    xlabel('Reward Prediction Error (a.u.)');
    ylabel('Signal Change (%)');

    y_min = floor(min(average - se) * 100) / 100;
    y_max = ceil(max(average + se) * 100) / 100;
    yticks(y_min:0.01:y_max);

    xlim([0.5, length(events) + 0.5]);

    %title(strrep(PSC(roi).roi_name, '_', ' '), 'FontWeight','bold', 'FontSize',14);
    grid off;

    % Optional: save plot
    % saveas(gcf, fullfile(Res_path, [PSC(roi).roi_name '_L_Amy_FWE05_PSC_line_fit_plot.png']));
end