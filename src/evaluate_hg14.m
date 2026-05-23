%% evaluate_hg14.m
% Evaluate accuracy on full dataset using ML model (DEBUG VERSION)

clc; clear; close all;

%% ----------- DATASET PATH -----------
dataset_path = "C:\Users\LENOVO\Desktop\Gestures";  % <-- MAIN FOLDER

gesture_folders = dir(dataset_path);
gesture_folders = gesture_folders([gesture_folders.isdir]);
gesture_folders = gesture_folders(~ismember({gesture_folders.name},{'.','..'}));

%% ----------- INIT -----------
total   = 0;
correct = 0;

fprintf('%-15s  %6s  %6s  %8s\n','Gesture','Tested','Correct','Accuracy');
fprintf('%s\n', repmat('-',1,45));

%% ----------- MAIN LOOP -----------
for f = 1:length(gesture_folders)

    folder_name = gesture_folders(f).name;
    folder_path = fullfile(dataset_path, folder_name);

    %% -------- IMAGE LOADING (PNG SUPPORT) --------
    img_files = dir(fullfile(folder_path, '*.*'));
    img_files = img_files(~[img_files.isdir]);

    valid_ext = {'.png','.jpg','.jpeg','.bmp'};
    filtered = [];

    for k = 1:length(img_files)
        [~,~,ext] = fileparts(img_files(k).name);
        if ismember(lower(ext), valid_ext)
            filtered = [filtered; img_files(k)];
        end
    end

    img_files = filtered;

    fprintf('DEBUG: %s → %d images found\n', folder_name, length(img_files));

    class_correct = 0;
    class_total   = 0;

    %% -------- IMAGE LOOP -----------
    for i = 1:length(img_files)

        try
            img_path = fullfile(folder_path, img_files(i).name);
            img = imread(img_path);

            %% Preprocessing
            [mask, edges, ~] = preprocess_hg14(img);

            % Skip bad masks
            if sum(mask(:)) < 500
                continue;
            end

            %% Feature extraction
            features = extract_features_hg14(mask, edges);

            %% ML Prediction
            label = classify_ml(features);

            class_total = class_total + 1;
            total       = total + 1;

            if strcmp(label, folder_name)
                class_correct = class_correct + 1;
                correct       = correct + 1;
            end

        catch ME
            % 🔥 SHOW ERROR (NO MORE SILENT FAIL)
            fprintf('ERROR in %s: %s\n', img_files(i).name, ME.message);
        end
    end

    acc = 100 * class_correct / max(class_total,1);

    fprintf('%-15s  %6d  %6d  %7.1f%%\n', ...
        folder_name, class_total, class_correct, acc);
end

fprintf('%s\n', repmat('-',1,45));
fprintf('%-15s  %6d  %6d  %7.2f%%\n', ...
    'OVERALL', total, correct, 100*correct/max(total,1));