clc; clear; close all;

%% -------- Load Input Image --------
input_image_path ="C:\Users\LENOVO\Desktop\Customised\palm\IMG_0028.jpg";
input_image = imread(input_image_path);

%% -------- Ensure 3-Channel RGB --------
if size(input_image, 3) == 1
    input_image = repmat(input_image, [1 1 3]);
end

%% -------- Run Preprocessing Pipeline --------
% 'auto' selects best segmentation (Otsu / Skin / Gloves)
[final_mask, edge_map, processing_stages] = preprocess_hg14(input_image, 'auto');

fprintf('Segmentation Mode Selected: %s\n', processing_stages.glove_mode);

%% -------- Display Pipeline Results --------
figure('Name','Hand Gesture Preprocessing Pipeline','Position',[50 50 1800 900]);
tiledlayout(2,4,'Padding','compact','TileSpacing','compact');

%% -------- Row 1 --------
nexttile;
imshow(input_image);
title('1. Input Image (Original RGB)','FontSize',14,'FontWeight','bold');

nexttile;
imshow(processing_stages.gray);
title('2. Grayscale Conversion','FontSize',14,'FontWeight','bold');

nexttile;
imshow(processing_stages.binary_raw);
title(['3. Initial Segmentation (' upper(processing_stages.glove_mode) ')'], ...
      'FontSize',14,'FontWeight','bold');

nexttile;
imshow(processing_stages.opened);
title('4. Noise Removal (Morphological Opening)','FontSize',14,'FontWeight','bold');

%% -------- Row 2 --------
nexttile;
imshow(processing_stages.closed);
title('5. Shape Refinement (Morphological Closing)','FontSize',14,'FontWeight','bold');

nexttile;
imshow(processing_stages.final_mask);
title('6. Final Hand Mask (Cleaned Region)','FontSize',14,'FontWeight','bold');

nexttile;
imshow(edge_map);
title('7. Edge Detection (Canny)','FontSize',14,'FontWeight','bold');

%% -------- Mask Overlay Visualization --------
nexttile;

% Resize mask to match original image
resized_mask = imresize(final_mask, [size(input_image,1) size(input_image,2)]);
binary_mask_uint8 = uint8(resized_mask);

% Create overlay
overlay_image = input_image;

overlay_image(:,:,1) = input_image(:,:,1) .* (1 - binary_mask_uint8); % suppress red
overlay_image(:,:,2) = min(uint8(255), input_image(:,:,2) + binary_mask_uint8 .* uint8(150)); % highlight green
overlay_image(:,:,3) = input_image(:,:,3) .* (1 - binary_mask_uint8); % suppress blue

imshow(overlay_image);
title('8. Final Output (Mask Overlay)','FontSize',14,'FontWeight','bold');