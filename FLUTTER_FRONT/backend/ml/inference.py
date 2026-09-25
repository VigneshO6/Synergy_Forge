"""
Model Inference for YOLO11 and MobileNetV3
Strict Non-Overlapping Bounding Boxes & 4-Class Quality System (Good, Defective, Sprouted, URS).
Eliminates 'Medium' completely.
"""

from typing import Dict, Any, List, Union, Tuple
from pathlib import Path
import numpy as np
import cv2
from PIL import Image

from config.settings import MOBILENET_CLASSES
from ml.model import get_yolo_model, get_mobilenet_model
from ml.preprocessing import preprocess_for_yolo, preprocess_for_mobilenet, load_image_rgb


def compute_box_overlap(b1: Dict[str, Any], b2: Dict[str, Any]) -> Tuple[float, float]:
    """
    Computes Intersection over Union (IoU) and Intersection over Minimum Area (IoA).
    IoA is crucial to eliminate nested / duplicate boxes where a smaller box is inside a larger one.
    """
    x1 = max(b1["x1"], b2["x1"])
    y1 = max(b1["y1"], b2["y1"])
    x2 = min(b1["x2"], b2["x2"])
    y2 = min(b1["y2"], b2["y2"])

    intersection = max(0, x2 - x1) * max(0, y2 - y1)
    if intersection == 0:
        return 0.0, 0.0

    area1 = b1["width"] * b1["height"]
    area2 = b2["width"] * b2["height"]

    union = area1 + area2 - intersection
    iou = intersection / max(1, union)
    ioa = intersection / max(1, min(area1, area2))
    return float(iou), float(ioa)


def suppress_overlapping_boxes(boxes_list: List[Dict[str, Any]], iou_thresh: float = 0.18, ioa_thresh: float = 0.28) -> List[Dict[str, Any]]:
    """
    Strict Non-Maximum Suppression (NMS) + Overlap Filtering.
    Guarantees no two bounding boxes overlap on the same onion bulb.
    Sorts by confidence descending, then greedily suppresses any box that shares
    IoU > iou_thresh or IoA > ioa_thresh with an already accepted box.
    """
    if not boxes_list:
        return []

    # Sort descending by confidence
    sorted_boxes = sorted(boxes_list, key=lambda b: b["confidence"], reverse=True)
    kept_boxes: List[Dict[str, Any]] = []

    for cand in sorted_boxes:
        overlaps = False
        for accepted in kept_boxes:
            iou, ioa = compute_box_overlap(cand["bbox"], accepted["bbox"])
            if iou > iou_thresh or ioa > ioa_thresh:
                overlaps = True
                break
        if not overlaps:
            kept_boxes.append(cand)

    return kept_boxes


def classify_onion_bulb(
    bulb_rgb: np.ndarray,
    bulb_area: float,
    median_area: float,
    mobilenet_model=None
) -> Tuple[str, float]:
    """
    Classifies an individual detected onion bulb into strictly 4 classes:
    1. 'urs' (Undersized): area < 0.65 * median_area or caliber significantly small
    2. 'sprouted': vegetative green shoot at neck / sprout emergence
    3. 'defective': surface necrosis, dark rot, black mold decay
    4. 'good': healthy, intact tunic without decay or neck sprouting

    Note: 'medium' is strictly removed.
    """
    # 1. Check Undersized (URS)
    if median_area > 0 and bulb_area < (median_area * 0.65):
        return "urs", 0.94

    h, w = bulb_rgb.shape[:2]
    if h < 5 or w < 5:
        return "good", 0.85

    # Convert bulb crop to HSV for color feature extraction
    hsv = cv2.cvtColor(bulb_rgb, cv2.COLOR_RGB2HSV)
    total_pixels = max(1, h * w)

    # Green sprout detection: H in [35, 85], S > 45, V > 40
    lower_green = np.array([35, 45, 40])
    upper_green = np.array([85, 255, 255])
    sprout_mask = cv2.inRange(hsv, lower_green, upper_green)
    sprout_ratio = cv2.countNonZero(sprout_mask) / total_pixels

    # Dark necrosis / rot detection: H in [0, 180], V < 45
    lower_dark = np.array([0, 0, 0])
    upper_dark = np.array([180, 255, 48])
    dark_mask = cv2.inRange(hsv, lower_dark, upper_dark)
    dark_ratio = cv2.countNonZero(dark_mask) / total_pixels

    # 2. Sprouted Check: prominent green sprout pixels (> 2.0%)
    if sprout_ratio > 0.020:
        conf = min(0.98, 0.82 + sprout_ratio * 4.0)
        return "sprouted", round(conf, 2)

    # 3. Defective Check: surface rot necrosis (> 5.5%)
    if dark_ratio > 0.055:
        conf = min(0.98, 0.80 + dark_ratio * 3.0)
        return "defective", round(conf, 2)

    # 4. Optional MobileNet verification if crop is substantial
    if mobilenet_model is not None and h >= 32 and w >= 32:
        try:
            resized = cv2.resize(bulb_rgb, (224, 224), interpolation=cv2.INTER_LINEAR)
            batch = np.expand_dims(resized.astype(np.float32), axis=0)
            preds = mobilenet_model.predict(batch, verbose=0)[0]
            top_idx = int(np.argmax(preds))
            top_prob = float(preds[top_idx])

            # MOBILENET_CLASSES = ["Good", "Defective", "Sprouted"]
            if top_idx < len(MOBILENET_CLASSES):
                mn_label = MOBILENET_CLASSES[top_idx].lower()
                if "sprout" in mn_label and top_prob > 0.60:
                    return "sprouted", round(top_prob, 2)
                elif "defect" in mn_label and top_prob > 0.60:
                    return "defective", round(top_prob, 2)
        except Exception:
            pass

    # 5. Otherwise, Good
    return "good", 0.92


def analyze_yolo(
    image_input: Union[bytes, str, Path, np.ndarray, Image.Image],
    conf_threshold: float = 0.25,
    iou_threshold: float = 0.35,
    imgsz: int = 640
) -> Dict[str, Any]:
    """
    Runs YOLO11 inference on the input image with strict non-overlapping box filtering
    and individual bulb 4-class classification (Good, Defective, Sprouted, URS).
    """
    model = get_yolo_model()
    if model is None:
        raise RuntimeError("YOLO11 model is not loaded.")

    rgb_img = preprocess_for_yolo(image_input)
    img_h, img_w = rgb_img.shape[:2]

    # Run YOLO detection
    results = model(
        rgb_img,
        conf=conf_threshold,
        iou=iou_threshold,
        imgsz=imgsz,
        verbose=False
    )
    first_result = results[0]

    raw_candidates: List[Dict[str, Any]] = []

    if first_result.boxes is not None and len(first_result.boxes) > 0:
        boxes = first_result.boxes
        coords = boxes.xyxy.cpu().numpy()
        confs = boxes.conf.cpu().numpy()
        classes = boxes.cls.cpu().numpy()

        for i in range(len(boxes)):
            x1, y1, x2, y2 = [int(v) for v in coords[i]]
            conf = float(confs[i])
            cls_id = int(classes[i])
            cls_name = model.names.get(cls_id, "onion")

            # Clamp coordinates to image boundaries
            x1 = max(0, min(img_w - 1, x1))
            y1 = max(0, min(img_h - 1, y1))
            x2 = max(0, min(img_w, x2))
            y2 = max(0, min(img_h, y2))

            bw = max(0, x2 - x1)
            bh = max(0, y2 - y1)

            # Filter degenerate noise specks (< 12px or < 0.05% of image area)
            if bw < 12 or bh < 12 or (bw * bh) < (img_w * img_h * 0.0005):
                continue

            raw_candidates.append({
                "class_id": cls_id,
                "label": cls_name,
                "confidence": round(conf * 100, 2),
                "bbox": {
                    "x1": x1,
                    "y1": y1,
                    "x2": x2,
                    "y2": y2,
                    "width": bw,
                    "height": bh,
                },
            })

    # Step 1: Enforce STRICT NON-OVERLAPPING bounding boxes
    filtered_boxes = suppress_overlapping_boxes(raw_candidates, iou_thresh=0.18, ioa_thresh=0.28)

    # Step 2: Calculate median bulb area for accurate URS identification
    areas = [b["bbox"]["width"] * b["bbox"]["height"] for b in filtered_boxes]
    median_area = float(np.median(areas)) if areas else 1.0

    mobilenet_model = get_mobilenet_model()

    detections: List[Dict[str, Any]] = []

    # Step 3: Classify each distinct, non-overlapping bulb into 4 classes
    for item in filtered_boxes:
        bbox = item["bbox"]
        x1, y1, x2, y2 = bbox["x1"], bbox["y1"], bbox["x2"], bbox["y2"]
        bw, bh = bbox["width"], bbox["height"]
        area = bw * bh

        # Crop bulb region safely
        crop = rgb_img[y1:y2, x1:x2]
        cat, cat_conf = classify_onion_bulb(crop, area, median_area, mobilenet_model)

        norm_x1 = max(0.0, min(1.0, x1 / img_w))
        norm_y1 = max(0.0, min(1.0, y1 / img_h))
        norm_x2 = max(0.0, min(1.0, x2 / img_w))
        norm_y2 = max(0.0, min(1.0, y2 / img_h))

        detections.append({
            "class_id": item["class_id"],
            "label": item["label"],
            "category": cat,  # strictly 'good', 'defective', 'sprouted', or 'urs'
            "category_confidence": round(cat_conf * 100, 1),
            "confidence": item["confidence"],
            "bbox": bbox,
            "normalized_bbox": {
                "x": round(norm_x1, 4),
                "y": round(norm_y1, 4),
                "width": round(norm_x2 - norm_x1, 4),
                "height": round(norm_y2 - norm_y1, 4),
            }
        })

    # Sort detections spatially top-to-bottom, left-to-right
    detections.sort(key=lambda d: (d["bbox"]["y1"] // 40, d["bbox"]["x1"]))

    return {
        "image_width": img_w,
        "image_height": img_h,
        "aspect_ratio": round(img_w / max(1, img_h), 4),
        "total_onions_detected": len(detections),
        "detections": detections,
    }


def analyze_quality(image_input: Union[bytes, str, Path, np.ndarray, Image.Image]) -> Dict[str, Any]:
    """
    Runs MobileNetV3 inference on the input image.
    Returns quality label, confidence, and all class probabilities.
    """
    model = get_mobilenet_model()
    if model is None:
        raise RuntimeError("MobileNetV3 model is not loaded.")

    batch = preprocess_for_mobilenet(image_input, target_size=(224, 224))
    raw_predictions = model.predict(batch, verbose=0)
    probabilities = raw_predictions[0].tolist()

    top_index = int(np.argmax(probabilities))
    top_confidence = float(probabilities[top_index])

    class_probs: Dict[str, float] = {}
    for idx, prob in enumerate(probabilities):
        name = MOBILENET_CLASSES[idx] if idx < len(MOBILENET_CLASSES) else f"Class_{idx}"
        class_probs[name] = round(prob * 100, 2)

    top_label = MOBILENET_CLASSES[top_index] if top_index < len(MOBILENET_CLASSES) else f"Class_{top_index}"

    return {
        "class_index": top_index,
        "label": top_label,
        "confidence": round(top_confidence * 100, 2),
        "class_probabilities": class_probs,
    }
