%% ============================================================
%% show_feature_extraction.m
%%
%% Displays:
%%   1. Original Image
%%   2. Final Hand Mask
%%   3. Extracted Features
%%
%% ============================================================

clc;
clear;
close all;

%% ============================================================
%% SET IMAGE PATH
%% ============================================================

img_path = ...
"C:\Users\LENOVO\Desktop\Customised\thumb\WhatsApp Image 2026-05-15 at 13.10.33.jpeg";

%% ============================================================
%% LOAD IMAGE
%% ============================================================

img = imread(img_path);

%% Convert grayscale to RGB

if size(img,3) == 1

    img = repmat(img,[1 1 3]);

end

%% ============================================================
%% PREPROCESSING
%% ============================================================

[mask, edges, stages] = preprocess_hg14(img);

%% ============================================================
%% FEATURE EXTRACTION
%% ============================================================

features = extract_features_hg14(mask, edges);

%% ============================================================
%% PRINT FEATURES IN COMMAND WINDOW
%% ============================================================

fprintf('\n========================================\n');
fprintf('     FEATURE EXTRACTION RESULT\n');
fprintf('========================================\n');

fprintf('area_norm    = %.4f\n', features.area_norm);
fprintf('aspect_ratio = %.4f\n', features.aspect_ratio);
fprintf('convexity    = %.4f\n', features.convexity);
fprintf('circularity  = %.4f\n', features.circularity);
fprintf('extent       = %.4f\n', features.extent);
fprintf('roughness    = %.4f\n', features.roughness);

fprintf('========================================\n\n');

%% ============================================================
%% FIGURE
%% ============================================================

figure( ...
    'Name','Feature Extraction', ...
    'Position',[100 100 1200 500]);

tiledlayout(1,3, ...
    'Padding','compact', ...
    'TileSpacing','compact');

%% ============================================================
%% PANEL 1 — ORIGINAL IMAGE
%% ============================================================

nexttile;

imshow(img);

title( ...
    '1. Original Image', ...
    'FontSize',14, ...
    'FontWeight','bold');

%% ============================================================
%% PANEL 2 — FINAL MASK
%% ============================================================

nexttile;

imshow(stages.final_mask);

title( ...
    '2. Final Hand Mask', ...
    'FontSize',14, ...
    'FontWeight','bold');

%% ============================================================
%% PANEL 3 — FEATURE EXTRACTION
%% ============================================================

nexttile;

axis off;

ax = gca;

ax.XLim = [0 1];
ax.YLim = [0 1];

%% Heading

text(0.5,0.92, ...
    'EXTRACTED FEATURES', ...
    'FontSize',16, ...
    'FontWeight','bold', ...
    'HorizontalAlignment','center', ...
    'Color',[0.1 0.1 0.1]);

%% Feature Text

feature_text = sprintf([ ...
    'Normalized Area : %.4f\n\n' ...
    'Aspect Ratio    : %.4f\n\n' ...
    'Convexity       : %.4f\n\n' ...
    'Circularity     : %.4f\n\n' ...
    'Extent          : %.4f\n\n' ...
    'Roughness       : %.4f'], ...
    features.area_norm, ...
    features.aspect_ratio, ...
    features.convexity, ...
    features.circularity, ...
    features.extent, ...
    features.roughness);

text(0.05,0.72, ...
    feature_text, ...
    'FontSize',12, ...
    'FontWeight','bold', ...
    'VerticalAlignment','top', ...
    'Color',[0.2 0.2 0.2]);