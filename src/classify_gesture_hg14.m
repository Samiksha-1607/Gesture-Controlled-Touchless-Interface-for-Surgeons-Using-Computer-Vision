function [label, action] = classify_gesture_hg14(features)
%% classify_gesture_hg14
%  Rules tuned from ACTUAL measured values:
%
%  Gesture_0 (Fist/dark bg): area=17811 AR=0.889 conv=0.731 circ=0.456 fing=1
%  Gesture_1 (Index up):     area=13817 AR=0.479 conv=0.898 circ=0.542 fing=1
%  Gesture_2-5 (Multi):      area=58564 AR=1.000 conv=1.017 circ=0.792 fing=1
%  Gesture_6 (Hang loose):   area=26463 AR=1.098 conv=0.827 circ=0.485 fing=2
%  Gesture_7 (Pinch):        area=13514 AR=0.682 conv=0.963 circ=0.732 fing=1
%  Gesture_8 (L-shape):      area=11789 AR=0.732 conv=0.715 circ=0.431 fing=1
%  Gesture_9 (Thumb):        area=13786 AR=1.256 conv=0.804 circ=0.546 fing=1
%  Gesture_10 (Hook):        area=17219 AR=0.710 conv=0.916 circ=0.588 fing=1
%  Gesture_11 (Horns):       area=14925 AR=0.786 conv=0.711 circ=0.380 fing=2
%  Gesture_12 (Gun):         area=13856 AR=0.493 conv=0.851 circ=0.443 fing=2
%  Gesture_13 (Flat):        area=14024 AR=0.578 conv=0.997 circ=0.767 fing=1

    area   = features.area;
    AR     = features.aspect_ratio;
    conv   = features.convexity;
    circ   = features.circularity;
    fing   = features.finger_count;

    label  = 'unknown';
    action = 'No action';

    if area < 500
        return;
    end

    %% Rule 1: Gesture_11 - Horns
    %  LOWEST convexity (0.711) + 2 fingers
    %  Checked before L-shape to catch 2-finger low-conv case
    if conv < 0.73 && fing >= 2
        label  = 'Gesture_11';
        action = 'HORNS - Brightness Up';

    %% Rule 2: Gesture_8 - L-shape
    %  Low convexity (0.715) + 1 finger + small area
    elseif conv < 0.73 && fing <= 1 && area < 15000
        label  = 'Gesture_8';
        action = 'L-SHAPE - Zoom In';

    %% Rule 3: Gesture_0 - Fist (dark background)
    %  YOUR MEASURED VALUES: conv=0.731 AR=0.889 area=17811 fing=1
    %  Unique: medium-low convexity (0.73-0.80) + square AR + medium area
    %  Convexity is low because wrist is included by Otsu on dark bg
    elseif conv >= 0.73 && conv < 0.80 && AR > 0.75 && AR < 1.10 && fing <= 1
        label  = 'Gesture_0';
        action = 'FIST - Stop / Hold';

    %% Rule 4: Gesture_9 - Thumb sideways
    %  Medium conv (0.804) + WIDEST AR (1.256)
    elseif AR > 1.15 && conv >= 0.78 && conv < 0.88
        label  = 'Gesture_9';
        action = 'THUMB - Reset View';

    %% Rule 5: Gesture_6 - Hang loose (thumb + pinky)
    %  Medium conv (0.827) + wide AR (1.098) + 2 fingers
    elseif conv >= 0.80 && conv < 0.87 && AR > 0.95 && fing >= 2
        label  = 'Gesture_6';
        action = 'HANG LOOSE - Swipe Next';

    %% Rule 6: Gesture_12 - Gun shape
    %  Medium conv (0.851) + NARROW AR (0.493) + 2 fingers
    elseif AR < 0.55 && fing >= 2 && conv > 0.82 && conv < 0.90
        label  = 'Gesture_12';
        action = 'GUN SHAPE - Previous Image';

    %% Rule 7: Gesture_1 - Index pointing up
    %  High conv (0.898) + VERY NARROW AR (0.479) + 1 finger + small area
    elseif AR < 0.55 && fing <= 1 && conv > 0.87 && area < 20000
        label  = 'Gesture_1';
        action = 'INDEX - Annotate Point';

    %% Rule 8: Gesture_7 - Pinch / OK
    %  HIGH conv (0.963) + medium circ (0.732) + small area + round-ish
    elseif conv > 0.93 && conv < 0.98 && circ > 0.65 && area < 20000
        label  = 'Gesture_7';
        action = 'PINCH/OK - Select Point';

    %% Rule 9: Gesture_10 - Index bent / hook
    %  High conv (0.916) + medium AR (0.710) + medium area
    elseif conv > 0.90 && conv < 0.94 && AR > 0.60 && AR < 0.80
        label  = 'Gesture_10';
        action = 'HOOK - Pan Left';

    %% Rule 10: Gesture_13 - Flat hand facing camera
    %  VERY HIGH conv (0.997) + narrow AR (0.578) + small area
    elseif conv > 0.97 && AR < 0.65 && area < 20000
        label  = 'Gesture_13';
        action = 'FLAT HAND - Confirm';

    %% Rule 11: Gesture_2/3/4/5 - Multi-finger open gestures
    %  Very large area (58564) + very high conv (1.017)
    %  All 4 share nearly identical features — use finger count
    elseif area > 38000 && conv > 0.90
        if fing <= 2
            label  = 'Gesture_2';
            action = 'TWO FINGERS - Zoom Out';
        elseif fing == 3
            label  = 'Gesture_3';
            action = 'THREE FINGERS - Next Image';
        elseif fing == 4
            label  = 'Gesture_4';
            action = 'FOUR FINGERS - Previous Image';
        else
            label  = 'Gesture_5';
            action = 'OPEN PALM - Scroll';
        end

    %% Rule 12: Medium area fallback
    %  Catches any remaining gestures by area + convexity band
    elseif area >= 20000 && area < 38000
        if conv > 0.95
            label  = 'Gesture_13';
            action = 'FLAT HAND - Confirm';
        elseif conv > 0.88
            label  = 'Gesture_10';
            action = 'HOOK - Pan Left';
        elseif AR > 1.05
            label  = 'Gesture_6';
            action = 'HANG LOOSE - Swipe Next';
        else
            label  = 'Gesture_0';
            action = 'FIST - Stop / Hold';
        end

    end

end