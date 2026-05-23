function label = classify_ml(features)

    persistent model mu sigma;

    % -------- Load model only once --------
    if isempty(model)
        data = load('gesture_ml_model.mat');
        model = data.model;
        mu    = data.mu;
        sigma = data.sigma;
    end

    % -------- Create feature vector --------
    X = [
        features.area_norm, ...
        features.aspect_ratio, ...
        features.convexity, ...
        features.circularity, ...
        features.extent, ...
        features.roughness, ...
        features.finger_count
    ];

    % -------- Normalize --------
    X = (X - mu) ./ sigma;

    % 🔥 IMPORTANT FIX (force row vector)
    X = reshape(X, 1, []);

    % -------- Predict --------
    % -------- Predict --------
label = string(predict(model, X));

% ==================================================
% FORCE OK → PALM
% ==================================================
if label == "07_ok"
    label = "01_palm";
end

end