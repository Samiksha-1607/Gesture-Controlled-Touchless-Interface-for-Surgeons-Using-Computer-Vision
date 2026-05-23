function features = extract_features_hg14(mask, edges)
%% ROBUST FEATURE EXTRACTION FOR ML

    features = struct();

    %% -------- Region Properties --------
    props = regionprops(mask, ...
        'Area','Perimeter','BoundingBox','Extent','ConvexArea');

    if isempty(props)
        features = empty_features();
        return;
    end

    [~, idx] = max([props.Area]);
    hand = props(idx);

    %% -------- Basic Features --------
    features.area = hand.Area;

    % 🔥 NEW: normalized area (VERY IMPORTANT)
    features.area_norm = hand.Area / numel(mask);

    features.perimeter = hand.Perimeter;
    features.bounding_box = hand.BoundingBox;

    %% -------- Aspect Ratio --------
    bb = hand.BoundingBox;
    if bb(4) > 0
        features.aspect_ratio = bb(3) / bb(4);
    else
        features.aspect_ratio = 1;
    end

    %% -------- Extent --------
    features.extent = hand.Extent;

    %% -------- Convexity --------
    if hand.ConvexArea > 0
        features.convexity = hand.Area / hand.ConvexArea;
    else
        features.convexity = 0;
    end

    %% -------- Circularity --------
    if hand.Perimeter > 0
        features.circularity = (4 * pi * hand.Area) / (hand.Perimeter^2);
    else
        features.circularity = 0;
    end

    %% -------- Roughness --------
    features.roughness = hand.Perimeter / sqrt(hand.Area + 1);

    %% -------- Finger Count (IMPROVED) --------
    features.finger_count = count_fingers_hg14(mask, bb);

end


%% ============================================================
function features = empty_features()
    features.area = 0;
    features.area_norm = 0;
    features.perimeter = 0;
    features.bounding_box = [0 0 0 0];
    features.aspect_ratio = 1;
    features.extent = 0;
    features.convexity = 0;
    features.circularity = 0;
    features.roughness = 0;
    features.finger_count = 0;
end


%% ============================================================
function fingers = count_fingers_hg14(mask, bb)
%% IMPROVED finger counting (more stable)

    try
        top_y  = max(1, round(bb(2)));
        bot_y  = min(size(mask,1), round(bb(2)+bb(4)));
        left_x = max(1, round(bb(1)));
        rgt_x  = min(size(mask,2), round(bb(1)+bb(3)));

        % 🔥 USE 50% REGION (more robust than 35%)
        top_50 = round(top_y + 0.50*(bot_y - top_y));
        top_50 = min(size(mask,1), top_50);

        region = mask(top_y:top_50, left_x:rgt_x);

        % 🔥 Smooth region (important)
        region = imclose(region, strel('line',5,0));

        col_sum = sum(region, 1);

        % adaptive threshold
        thresh = max(5, 0.01 * max(col_sum));
        col_bin = col_sum > thresh;

        transitions = diff([0 col_bin 0]);
        fingers = sum(transitions == 1);

        % clamp
        fingers = max(0, min(6, fingers));

    catch
        fingers = 0;
    end
end