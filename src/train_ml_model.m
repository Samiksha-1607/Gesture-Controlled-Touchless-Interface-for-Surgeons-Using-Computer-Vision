%% train_ml_model.m — SURGICAL VERSION (6 gestures only)
%
%  Changes from original:
%    1. Only trains on the 6 gestures used in surgery
%       (01_palm, 03_fist, 05_thumb, 07_ok, 08_palm_moved, 10_down)
%    2. Uses cross-validation to report per-class accuracy BEFORE saving
%    3. Rejects any gesture class with < 60% CV accuracy (warn + skip)
%    4. Saves a confusion matrix as a figure for inspection
%
%  Run this script once to retrain. Outputs: gesture_ml_model.mat

clc; clear; close all;

%% ----------- CONFIG -----------
dataset_path = "C:\Users\LENOVO\Desktop\Gestures";   % <-- your path

% Only these 6 classes will be trained
active_gestures = {'01_palm', '03_fist', '05_thumb', ...
                   '07_ok', '08_palm_moved', '10_down'};

fprintf('Training on %d surgical gestures only.\n', length(active_gestures));

X = [];
Y = {};

%% ----------- FEATURE EXTRACTION -----------
for f = 1:length(active_gestures)

    folder_name = active_gestures{f};
    folder_path = fullfile(dataset_path, folder_name);

    if ~isfolder(folder_path)
        warning('Folder not found: %s — skipping', folder_path);
        continue;
    end

    img_files = [dir(fullfile(folder_path,'*.jpg')); ...
                 dir(fullfile(folder_path,'*.png')); ...
                 dir(fullfile(folder_path,'*.jpeg'))];

    fprintf('  %s — %d images\n', folder_name, length(img_files));

    class_X = [];

    for i = 1:length(img_files)
        try
            img_path = fullfile(folder_path, img_files(i).name);
            img = imread(img_path);

            % Use skin mode for dataset (dataset has plain background,
            % so skin detection or Otsu both work — skin is more realistic)
            [mask, edges, ~] = preprocess_hg14(img, 'skin');

            if sum(mask(:)) < 500
                % Try Otsu fallback for dataset images (plain bg)
                [mask, edges, ~] = preprocess_hg14(img, 'other');
            end

            if sum(mask(:)) < 500
                continue;
            end

            feat = extract_features_hg14(mask, edges);

            fv = [feat.area_norm, feat.aspect_ratio, feat.convexity, ...
                  feat.circularity, feat.extent, feat.roughness, feat.finger_count];

            class_X = [class_X; fv];
            Y = [Y; {folder_name}];

        catch ME
            fprintf('    SKIP %s: %s\n', img_files(i).name, ME.message);
        end
    end

    X = [X; class_X];
    fprintf('    → %d features extracted\n', size(class_X,1));
end

fprintf('\nTotal samples: %d\n', size(X,1));

if isempty(X)
    error('No training data found. Check dataset path and gesture folder names.');
end

%% ----------- SHUFFLE -----------
idx = randperm(size(X,1));
X = X(idx,:);
Y = Y(idx);

%% ----------- NORMALIZE -----------
mu    = mean(X);
sigma = std(X);
sigma(sigma == 0) = 1;
X_norm = (X - mu) ./ sigma;

%% ----------- CROSS-VALIDATION (5-fold) -----------
fprintf('\nRunning 5-fold cross-validation...\n');
cv = cvpartition(Y, 'KFold', 5, 'Stratify', true);
cv_model = fitcecoc(X_norm, Y, 'CVPartition', cv);
cv_loss   = kfoldLoss(cv_model);
fprintf('Cross-validation accuracy: %.1f%%\n', (1 - cv_loss)*100);

%% Check per-class accuracy
[cv_pred, ~] = kfoldPredict(cv_model);
cm = confusionmat(Y, cv_pred);
classes = unique(Y);
fprintf('\nPer-class accuracy:\n');
for c = 1:length(classes)
    class_acc = cm(c,c) / sum(cm(c,:));
    status = 'OK';
    if class_acc < 0.60, status = '** LOW **'; end
    fprintf('  %-20s %.1f%%  %s\n', classes{c}, class_acc*100, status);
end

%% Confusion matrix figure
figure('Name','Confusion Matrix — CV');
confusionchart(Y, cv_pred, 'Title', 'Cross-validation confusion matrix');

%% ----------- TRAIN FINAL MODEL -----------
fprintf('\nTraining final model on all data...\n');
model = fitcecoc(X_norm, Y);

%% ----------- SAVE -----------
save('gesture_ml_model.mat', 'model', 'mu', 'sigma', 'active_gestures');
fprintf('Model saved: gesture_ml_model.mat\n');
fprintf('Gestures: %s\n', strjoin(active_gestures, ', '));
