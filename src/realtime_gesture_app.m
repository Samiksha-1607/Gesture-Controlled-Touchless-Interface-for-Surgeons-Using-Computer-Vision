%% ============================================================
%% realtime_gesture_medical_viewer.m
%%
%% TOUCHLESS MRI / XRAY VIEWER USING HAND GESTURES
%%
%% GESTURES:
%% 01_palm        -> CONTINUOUS ZOOM IN
%% 03_fist        -> CONTINUOUS ZOOM OUT
%% 08_palm_moved  -> NEXT IMAGE
%% 05_thumb       -> PREVIOUS IMAGE
%%
%% ============================================================

clc;
clear;
close all;

%% ============================================================
%% RESET CAMERA
%% ============================================================

clear cam;

imaqreset;

pause(3);

%% ============================================================
%% CHECK WEBCAM
%% ============================================================

cams = webcamlist;

disp('Available Cameras:');
disp(cams);

if isempty(cams)

    error('No webcam detected');

end

%% ============================================================
%% INITIALIZE CAMERA
%% ============================================================

try

    cam = webcam(1);

catch

    error(['Could not access webcam.' newline ...
           'Close Zoom / Teams / Browser / Camera App']);

end

%% ============================================================
%% SET CAMERA RESOLUTION
%% ============================================================

disp('Supported Resolutions:');
disp(cam.AvailableResolutions);

cam.Resolution = cam.AvailableResolutions{1};

pause(2);

disp('======================================');
disp('SURGICAL MRI/XRAY VIEWER STARTED');
disp('======================================');

%% ============================================================
%% LOAD MRI / XRAY IMAGES
%% ============================================================

medical_imgs = {

    imread("C:\Users\LENOVO\Desktop\Customised\5ded45de-a767-41df-84ca-58023bfccb9a.jpg")
    imread("C:\Users\LENOVO\Desktop\Customised\5fd861f1-cfde-41dc-a076-0b36974b5af6.jpg")
    imread("C:\Users\LENOVO\Desktop\Customised\e69ff5fe-e5cf-48eb-bf54-cead215668fc.jpg")
    imread("C:\Users\LENOVO\Desktop\Customised\download.jpg")

};

img_idx = 1;

zoom_factor = 1;

%% ============================================================
%% FRAME SETTINGS
%% ============================================================

frame_w = 640;
frame_h = 480;

%% ============================================================
%% ROI SETTINGS
%% ============================================================

roi_w = 260;
roi_h = 260;

roi_x = round((frame_w - roi_w)/2);
roi_y = round((frame_h - roi_h)/2);

%% ============================================================
%% STABILITY SETTINGS
%% ============================================================

buffer_size = 7;

confirm_frames = 5;

label_buffer = repmat("unknown",1,buffer_size);

stable_count = 0;

last_confirmed = "none";

%% ============================================================
%% FIGURE
%% ============================================================

fig = figure( ...
    'Name','Touchless MRI/Xray Viewer', ...
    'NumberTitle','off');

%% ============================================================
%% MAIN LOOP
%% ============================================================

while ishandle(fig)

    %% --------------------------------------------------------
    %% GET CAMERA FRAME
    %% --------------------------------------------------------

    frame = snapshot(cam);

    frame = fliplr(frame);

    frame = imresize(frame,[frame_h frame_w]);

    %% --------------------------------------------------------
    %% ROI
    %% --------------------------------------------------------

    r1 = roi_y;
    r2 = roi_y + roi_h;

    c1 = roi_x;
    c2 = roi_x + roi_w;

    roi = frame(r1:r2,c1:c2,:);

    %% --------------------------------------------------------
    %% PREPROCESS
    %% --------------------------------------------------------

    [mask,~,~] = preprocess_hg14(roi,'skin');

    mask_area = sum(mask(:));

    %% --------------------------------------------------------
    %% CLASSIFICATION
    %% --------------------------------------------------------

    if mask_area < 2000

        label = "no_hand";

        action = "Waiting for hand...";

        stable_count = 0;

    else

        features = extract_features_hg14( ...
            mask, ...
            edge(mask,'Canny',[0.02 0.12]));

        label_raw = string(classify_ml(features));

        %% ----------------------------------------------------
        %% SMOOTHING
        %% ----------------------------------------------------

        label_buffer = [label_buffer(2:end), label_raw];

        unique_labels = unique(label_buffer);

        vote_counts = zeros(1,length(unique_labels));

        for k = 1:length(unique_labels)

            vote_counts(k) = sum(label_buffer == unique_labels(k));

        end

        [~,best_idx] = max(vote_counts);

        stable_label = unique_labels(best_idx);

        %% ----------------------------------------------------
        %% HOLD CONFIRMATION
        %% ----------------------------------------------------

        if strcmp(stable_label,label_buffer(end-1)) && ...
           strcmp(stable_label,label_buffer(end))

            stable_count = stable_count + 1;

        else

            stable_count = 0;

        end

        label = stable_label;

        %% ----------------------------------------------------
        %% CONTINUOUS ACTIONS
        %% ----------------------------------------------------

        if stable_count >= confirm_frames

            %% ================================================
            %% CONTINUOUS ZOOM IN
            %% ================================================

            if strcmp(label,"01_palm")

                zoom_factor = min(3, zoom_factor + 0.03);

                action = "ZOOM IN";

            %% ================================================
            %% CONTINUOUS ZOOM OUT
            %% ================================================

            elseif strcmp(label,"03_fist")

                zoom_factor = max(1, zoom_factor - 0.03);

                action = "ZOOM OUT";

            %% ================================================
            %% NEXT IMAGE
            %% ================================================

            elseif strcmp(label,"08_palm_moved")

                if ~strcmp(last_confirmed,label)

                    img_idx = img_idx + 1;

                    if img_idx > length(medical_imgs)

                        img_idx = 1;

                    end

                    last_confirmed = label;

                end

                action = "NEXT IMAGE";

            %% ================================================
            %% PREVIOUS IMAGE
            %% ================================================

            elseif strcmp(label,"05_thumb")

                if ~strcmp(last_confirmed,label)

                    img_idx = img_idx - 1;

                    if img_idx < 1

                        img_idx = length(medical_imgs);

                    end

                    last_confirmed = label;

                end

                action = "PREVIOUS IMAGE";

            else

                action = "NO ACTION";

            end

        else

            action = sprintf( ...
                'Detecting... [%d/%d]', ...
                stable_count, ...
                confirm_frames);

        end

    end

    %% ========================================================
    %% DRAW ROI
    %% ========================================================

    frame = insertShape( ...
        frame, ...
        'Rectangle', ...
        [c1 r1 roi_w roi_h], ...
        'Color','green', ...
        'LineWidth',3);

    %% ========================================================
    %% MEDICAL IMAGE WITH REAL ZOOM
    %% ========================================================

    medical_img = medical_imgs{img_idx};

    %% Convert grayscale to RGB

    if size(medical_img,3) == 1

        medical_img = cat(3, ...
            medical_img, ...
            medical_img, ...
            medical_img);

    end

    %% Original image size

    [h,w,~] = size(medical_img);

    %% Zoom image

    zoomed_img = imresize(medical_img, zoom_factor);

    [zh,zw,~] = size(zoomed_img);

    %% Center crop

    crop_h = min(h, zh);
    crop_w = min(w, zw);

    start_x = round((zw - crop_w)/2);
    start_y = round((zh - crop_h)/2);

    start_x = max(1,start_x);
    start_y = max(1,start_y);

    cropped = zoomed_img( ...
        start_y:start_y+crop_h-1, ...
        start_x:start_x+crop_w-1, ...
        :);

    %% Resize for display

    medical_img = imresize(cropped,[480 640]);

    %% ========================================================
    %% DISPLAY
    %% ========================================================

    subplot(1,2,1);

    imshow(frame);

    title('Live Camera');

    subplot(1,2,2);

    imshow(medical_img);

    title('MRI / XRAY VIEWER');

    %% ========================================================
    %% TITLE
    %% ========================================================

    sgtitle( ...
        sprintf( ...
        'Gesture: %s   |   Action: %s   |   Zoom: %.1fx', ...
        char(label), ...
        char(action), ...
        zoom_factor));

    drawnow;

end

%% ============================================================
%% CLEANUP
%% ============================================================

clear cam;

disp('Application Closed');