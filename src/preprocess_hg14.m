    function [mask, edges, stages] = preprocess_hg14(img_rgb, glove_mode)
%% preprocess_hg14


    if nargin < 2
        glove_mode = 'auto';
    end

    stages = struct();

    %% -------- Ensure RGB --------
    if size(img_rgb, 3) == 1
        img_rgb = repmat(img_rgb, [1 1 3]);
    end
    stages.original = img_rgb;

    %% -------- Resize to standard size --------
    img_rgb = imresize(img_rgb, [240 320]);

    %% -------- Grayscale --------
    img_gray = rgb2gray(img_rgb);
    stages.gray = img_gray;

    %% -------- Auto-detect mode --------
    if strcmp(glove_mode, 'auto')
        % If image is very dark on average = high contrast dataset style
        % If image has moderate brightness = real camera feed
        mean_brightness = mean(img_gray(:));
        if mean_brightness < 60
            % Dark background image → use Otsu (brightness-based)
            glove_mode = 'otsu';
        else
            % Normal lighting → use skin detection
            glove_mode = 'skin';
        end
    end

    stages.glove_mode = glove_mode;

    %% -------- Segmentation based on mode --------
    switch glove_mode

        case 'skin'
            %% YCrCb skin detection
            img_ycrcb = rgb2ycbcr(img_rgb);
            Cr = img_ycrcb(:,:,2);
            Cb = img_ycrcb(:,:,3);
            skin_mask = (Cr >= 133 & Cr <= 173) & (Cb >= 77 & Cb <= 127);

            img_hsv = rgb2hsv(img_rgb);
            H = img_hsv(:,:,1);
            S = img_hsv(:,:,2);
            V = img_hsv(:,:,3);
            hsv_mask = ((H < 0.10) | (H > 0.90)) & (S > 0.10) & (V > 0.20);

            img_binary = skin_mask | hsv_mask;

        case 'latex'
            %% Blue/purple latex glove
            img_hsv = rgb2hsv(img_rgb);
            H = img_hsv(:,:,1);
            S = img_hsv(:,:,2);
            V = img_hsv(:,:,3);
            img_binary = (H >= 0.55 & H <= 0.80) & (S > 0.15) & (V > 0.10);

        case 'nitrile'
            %% Dark nitrile gloves — adaptive threshold
            img_enhanced = adapthisteq(img_gray);
            img_binary   = imbinarize(img_enhanced, 'adaptive', ...
                                      'ForegroundPolarity', 'dark', ...
                                      'Sensitivity', 0.4);
            img_binary = ~img_binary;

        otherwise
            %% Otsu — for high contrast dataset images (dark background)
            img_enhanced = adapthisteq(img_gray);
            img_blur     = imgaussfilt(img_enhanced, 1.2);
            img_binary   = imbinarize(img_blur);
            if mean(img_binary(:)) > 0.5
                img_binary = ~img_binary;
            end

    end

    stages.binary_raw = img_binary;

    %% -------- Noise removal --------
    img_binary = bwareaopen(img_binary, 300);

    %% -------- Morphology --------
    se_open  = strel('disk', 2);
    se_close = strel('disk', 8);

    img_opened = imopen(img_binary, se_open);
    stages.opened = img_opened;
    
    img_closed = imclose(img_opened, se_close);
    stages.closed = img_closed;

    %% -------- Fill holes --------
    img_filled = imfill(img_closed, 'holes');

    %% -------- Keep largest region --------
    img_filled = bwareafilt(img_filled, 1);
    stages.final_mask = img_filled;
    mask = img_filled;

    %% -------- Validate --------
    if sum(mask(:)) < 500
        mask = false(size(img_filled));
        stages.final_mask = mask;
    end

    %% -------- Edges --------
    edges = edge(mask, 'Canny', [0.02 0.12]);
    stages.edges = edges;

end