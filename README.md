# 🏥 Gesture-Controlled Touchless Interface for Surgeons Using Computer Vision

> A real-time hand gesture recognition system built in MATLAB that allows surgeons to control medical image viewers (MRI / X-Ray) without touching any surface — maintaining sterility in the operation theatre.

---

## 📌 Project Overview

In surgical environments, doctors cannot touch keyboards or mice due to sterility requirements. This system uses a **webcam** to detect and classify hand gestures in real-time, allowing surgeons to:

- 🔍 Zoom In / Zoom Out medical images
- 🖼️ Navigate between MRI / X-Ray images
- ✋ Control the viewer completely hands-free

---

## 🧠 How It Works
Camera Feed → Preprocessing → Feature Extraction → ML Classification → Action

1. **Capture** — Webcam captures live hand image
2. **Preprocess** — Skin segmentation, morphological operations, edge detection
3. **Extract Features** — Area, convexity, circularity, finger count, aspect ratio
4. **Classify** — SVM-based ML model predicts gesture
5. **Act** — Triggers zoom, navigation, or other actions



## 🖐️ Supported Gestures

| Gesture | Action |
|---------|--------|
| ✋ Open Palm | Zoom In |
| ✊ Fist | Zoom Out |
| 👍 Thumbs Up | Previous Image |
| 🖐️ Palm Moved | Next Image |
| ☝️ Index Finger | Annotate Point |
| 👌 OK / Pinch | Select / Confirm |

---

## ⚙️ Preprocessing Pipeline

All 20 techniques applied to each frame:

| Step | Technique |
|------|-----------|
| 1 | RGB Channel Normalization |
| 2 | Image Resizing (256×256) |
| 3 | Grayscale Conversion |
| 4 | Brightness Analysis |
| 5 | YCrCb Skin Segmentation |
| 6 | HSV Color Segmentation |
| 7 | Combined Skin Mask |
| 8 | Adaptive Histogram Equalization (CLAHE) |
| 9 | Gaussian Filtering / Blur |
| 10 | Otsu Thresholding |
| 11 | Adaptive Thresholding |
| 12 | Binary Thresholding |
| 13 | Image Inversion / Complementing |
| 14 | Noise Removal (bwareaopen) |
| 15 | Morphological Opening |
| 16 | Morphological Closing |
| 17 | Hole Filling |
| 18 | Largest Connected Component (bwareafilt) |
| 19 | Mask Validation |
| 20 | Canny Edge Detection |

---

## 🤖 Machine Learning Model

- **Algorithm:** SVM with ECOC (Error-Correcting Output Codes)
- **Features:** Normalized Area, Aspect Ratio, Convexity, Circularity, Extent, Roughness, Finger Count
- **Training:** 5-fold cross-validation
- **Toolbox:** MATLAB Statistics and Machine Learning Toolbox

---

## 🛠️ Requirements

- MATLAB R2020b or later
- Image Processing Toolbox
- Statistics and Machine Learning Toolbox
- Computer Vision Toolbox
- Webcam Support Package

---

## 🚀 How to Run

### 1. Test Preprocessing on a Single Image
```matlab
run('src/show_preprocessing.m')
```

### 2. Train the ML Model
```matlab
run('src/train_ml_model.m')
```

### 3. Evaluate Accuracy on Dataset
```matlab
run('src/evaluate_hg14.m')
```

### 4. Launch Live Webcam App
```matlab
run('src/realtime_gesture_app.m')
```

---

## 📊 Results

- Real-time gesture classification via webcam
- Supports 6 surgical gestures
- Stable prediction using 7-frame voting buffer
- Touchless MRI / X-Ray image navigation

---

## 📄 License

This project is for academic and research purposes.

---

> *"Empowering surgeons with touchless control — because sterility saves lives."*
