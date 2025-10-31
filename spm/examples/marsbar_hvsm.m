function MARSBAR_script_hvsm
% MarsBaR batch script
%
% Niamh C (April 2025), Nadege B (April 2008), largely cannibalized from
% run_tutorial in the example marsbar data set (batch directory) by matthewbrett
% See http://marsbar.sourceforge.net
% Edited by Keanu Toomer (Nov 2025)

%%%%%%%%%%%%%%%%%%%%%%%% Edit here %%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Directory specifications
baseDir = '/media/STUDY-HP-LloH-HV-010622/03_derivatives/spm-stats/';
model = 'model-parametricImage_response_14_10_25';

% Participants to manually include/exclude - leave blank to read all
include = [];
exclude = ['sub-mueh0210']; % <- pilot data subjects = ['sub-jnsu0132'; 'sub-lzdv1218'; 'sub-pttr0360'], log file error subject = ['sub-mueh0210']

% ROIs to include - if using all ROI contained in roiPath, type roiNames='inf'
%roiNames = {'model_1_ibNIB_23_-44_-15_roi.mat'}; 
roiNames = {'inf'}; 

% Event settings
% Define events and their corresponding labels
events = {'Image' 'Response'}; % verbatim to SPM specification
eventLabels = {'Image' 'Subjective Rating' 'Response'}; % used for ploting
eventDuration = 0;  % Default event duration (in seconds)

together = 1;  % 0 for no, 1 for averaging across the same events
time_course = 'Fitted';  % Options: 'FIR' or 'Fitted'

% Plot results?
plot_res = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%% Main %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% path to directory containing subjects' models estimation results. 
modelDir = fullfile(baseDir, model, 'first_level');
% path to directory containing ROIs
roiPath = fullfile(baseDir, model, 'group_level', 'ROIs');

% Get subject IDs
if ~isempty(include)
    sub_names = select_IDs(include, [], exclude);
else
    sub_names = select_IDs(modelDir, 'sub-*', exclude);
end
fprintf('%d participants identified\n', numel(sub_names));

% folder where to save marsbar reconfigured design
Est_path = fullfile(baseDir, model, 'ROI_analysis');
% folder where to save results, time course...
Res_path = fullfile(baseDir, model, 'ROI_results');

% Add MarsBaR script folder to the path
addpath(genpath('/home/Researcher/marsbar-0.44'));

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
if strcmp(roiNames, 'inf')
    roiList = dir(fullfile(roiPath, '*roi.mat'));
    roiNames = {roiList.name}';
    if isempty(roiList), disp('No ROI file in ROI folder'), end
end

% Load ROIs
for i = 1:numel(roiNames)
    ROI_array{i} = maroi(fullfile(roiPath, roiNames{i}));
end

%% Main processing loop for all subjects and ROIs
for subject = 1:numel(sub_names)
    modelDir = fullfile(modelDir, sub_names{subject});
    disp(modelDir);

    clear model_file
    modelFile = fullfile(modelDir, 'SPM.mat');
    Est_dir = fullfile(Est_path, sub_names{subject});

    % Create analysis directory if it doesn't exist
    if ~exist(Est_dir, 'dir')
        mkdir(Est_dir);
    end


    % ROI file shows a binary mask of the ROI region throughout the time series,
    % this has been manually created with MarsBaR GUI and saved in the ROI_path directory
    %
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

        % get design betas
        b = betas(E);

        [event_spec, event_names] = event_spects(E);
        n_event_types = size(event_spec, 2);


        if subject == 1
            Data(roi_no).roi_name = roiNames{roi_no};
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
    end
end

%% Save results and summaries
save(fullfile(Res_path, 'roi_data.mat'), 'TC', 'PSC', 'Data');