"""
Deep Learning Produce Analysis Pipeline
Orchestrates YOLO11 object detection and MobileNetV3 deep quality classification.
Enforces zero bounding box overlap and strict 4-class produce breakdown:
- Good Quality (Grade A)
- Defective / Fungal Rot / Mold
- Sprouted / Vegetative Growth
- URS (Undersized / Small Bulbs)
Medium is strictly removed everywhere.
"""

import time
from typing import Dict, Any, Union, List
from pathlib import Path
import numpy as np

from dl.yolo_detector import yolo_detector
from dl.mobilenet_classifier import mobilenet_classifier
from dl.preprocessing import extract_bulb_crop


class DeepLearningAnalysisPipeline:
    """
    End-to-end Deep Learning Inspection Pipeline.
    """

    def analyze(
        self,
        image_input: Union[bytes, str, Path, np.ndarray],
        batch_id: str = "BTH-LIVE"
    ) -> Dict[str, Any]:
        start_time = time.perf_counter()

        # Step 1: Deep YOLO11 Detection with non-overlapping bounding boxes
        yolo_out = yolo_detector.detect(image_input)
        raw_detections = yolo_out["detections"]
        total_onions = yolo_out["total_onions"]
        rgb_img = yolo_out["rgb_image"]
        w = yolo_out["image_width"]
        h = yolo_out["image_height"]

        # Step 2: Calculate median bulb area for lot caliber baseline
        if total_onions > 0:
            areas = [d["area"] for d in raw_detections]
            median_area = float(np.median(areas))
        else:
            median_area = 0.0

        # Step 3: Per-bulb classification using MobileNetV3 and morphology
        annotated_detections: List[Dict[str, Any]] = []
        for det in raw_detections:
            bbox = det["bbox"]
            bulb_crop = extract_bulb_crop(rgb_img, bbox)
            cat, cat_conf, bulb_metrics = mobilenet_classifier.classify_bulb(bulb_crop, det["area"], median_area)

            # Assign category and display labels
            display_map = {
                "good": "Good (Grade A)",
                "defective": "Defective (Rot/Mold)",
                "sprouted": "Sprouted",
                "urs": "URS (Undersized)",
            }

            color_map = {
                "good": "#10B981",       # Emerald Green
                "defective": "#EF4444",  # Crimson Red
                "sprouted": "#F59E0B",   # Amber
                "urs": "#6366F1",        # Indigo
            }

            det["category"] = cat
            det["category_display"] = display_map.get(cat, "Good (Grade A)")
            det["category_confidence"] = cat_conf
            det["box_color"] = color_map.get(cat, "#10B981")
            det["diameter_mm"] = bulb_metrics.get("diameter_mm", det.get("diameter_mm", 45.0))
            det["sphericity"] = bulb_metrics.get("sphericity", 0.90)
            det["caliber_class"] = bulb_metrics.get("caliber_class", "Standard")
            det["defect_score"] = bulb_metrics.get("defect_score", 0.0)
            annotated_detections.append(det)

        # Step 4: Run MobileNetV3 lot-level quality classification (only when produce exists)
        if total_onions > 0:
            lot_quality = mobilenet_classifier.classify_lot(rgb_img)

            good_count = sum(1 for d in annotated_detections if d["category"] == "good")
            defective_count = sum(1 for d in annotated_detections if d["category"] == "defective")
            sprouted_count = sum(1 for d in annotated_detections if d["category"] == "sprouted")
            urs_count = sum(1 for d in annotated_detections if d["category"] == "urs")

            good_pct = round((good_count / total_onions) * 100.0, 1)
            defective_pct = round((defective_count / total_onions) * 100.0, 1)
            sprouted_pct = round((sprouted_count / total_onions) * 100.0, 1)
            urs_pct = round((urs_count / total_onions) * 100.0, 1)

            avg_diameter = round(float(np.mean([d["diameter_mm"] for d in annotated_detections])), 1)
            avg_sphericity = round(float(np.mean([d["sphericity"] for d in annotated_detections])), 2)

            # Grade determination without Medium
            if good_pct >= 75.0:
                overall_grade = "Good (Grade A)"
            elif good_pct >= 50.0:
                overall_grade = "Commercial (Grade A/B)"
            elif defective_pct >= 25.0:
                overall_grade = "High Defect Lot"
            elif sprouted_pct >= 20.0:
                overall_grade = "Sprouted Lot"
            else:
                overall_grade = "Needs Sorting / URS Segregation"

            summary = (
                f"DL Engine identified {total_onions} non-overlapping onion bulbs. "
                f"Strict 4-Class Breakdown: {good_count} Good ({good_pct}%), {defective_count} Defective ({defective_pct}%), "
                f"{sprouted_count} Sprouted ({sprouted_pct}%), {urs_count} URS ({urs_pct}%). "
                f"Average caliber: {avg_diameter} mm (Sphericity: {avg_sphericity})."
            )

            observations = [
                f"Segmented {total_onions} non-overlapping onion bulb(s) using YOLO11 deep neural network.",
                f"MobileNetV3 produce model confidence: {lot_quality['confidence']}%.",
                f"Strict 4-Class produce breakdown: Good ({good_pct}%), Defective ({defective_pct}%), Sprouted ({sprouted_pct}%), URS ({urs_pct}%).",
            ]
            if avg_diameter > 0:
                observations.append(f"Geometric sizing caliber: Average {avg_diameter} mm with {avg_sphericity} sphericity index.")
            if urs_count > 0:
                observations.append(f"Detected {urs_count} undersized (URS) bulb(s) suitable for size sorting.")
            if sprouted_count > 0:
                observations.append(f"Identified {sprouted_count} bulb(s) exhibiting early neck sprout emergence.")
            if defective_count > 0:
                observations.append(f"Identified {defective_count} bulb(s) with exterior tunic rot or mold lesions.")
        else:
            good_count = defective_count = sprouted_count = urs_count = 0
            good_pct = defective_pct = sprouted_pct = urs_pct = 0.0
            avg_diameter = 0.0
            avg_sphericity = 0.0
            overall_grade = "No Onions Detected"
            lot_quality = {
                "label": "No Onions Detected",
                "class_index": -1,
                "confidence": 0.0,
                "class_probabilities": {"Good": 0.0, "Defective": 0.0, "Sprouted": 0.0},
            }
            summary = (
                "Zero onion bulbs detected in the uploaded image. "
                "The visual content does not match onion produce (Allium cepa). "
                "Please photograph or upload clear, visible onion bulbs on a grading tray."
            )
            observations = [
                "Deep neural network (YOLO11) scanned the image for onion bulbs (Allium cepa).",
                "Zero onion bulbs identified in the frame.",
                "Visual features do not match agricultural onion produce (e.g. non-produce diagram, screenshot, or empty surface).",
                "Recommendation: Place real onion bulbs on a clean grading surface under good lighting and recapture.",
            ]

        elapsed_ms = round((time.perf_counter() - start_time) * 1000.0, 1)

        return {
            "success": True,
            "engine": "DeepLearning-YOLO11+MobileNetV3",
            "batch_id": batch_id,
            "total_onions": total_onions,
            "image_width": w,
            "image_height": h,
            "counts": {
                "good": good_count,
                "defective": defective_count,
                "sprouted": sprouted_count,
                "undersized": urs_count,
            },
            "percentages": {
                "good": good_pct,
                "defective": defective_pct,
                "sprouted": sprouted_pct,
                "undersized": urs_pct,
            },
            "calibers": {
                "average_diameter_mm": avg_diameter,
                "average_sphericity": avg_sphericity,
                "grade_a_count": sum(1 for d in annotated_detections if d.get("caliber_class") == "Grade A Large (>55mm)"),
                "commercial_count": sum(1 for d in annotated_detections if "Commercial" in d.get("caliber_class", "")),
                "urs_count": urs_count,
            },
            "quality": {
                "label": overall_grade,
                "class_index": lot_quality["class_index"],
                "confidence": lot_quality["confidence"],
                "class_probabilities": lot_quality["class_probabilities"],
            },
            "detections": annotated_detections,
            "observations": observations,
            "summary": summary,
            "processing_time_ms": elapsed_ms,
            "disclaimer": (
                "The deep learning image-processing system primarily evaluates externally visible onion quality "
                "characteristics from RGB images. Internal defects that cannot be visually observed "
                "are not detected by standard RGB cameras."
            ),
        }


# Singleton pipeline instance
deep_pipeline = DeepLearningAnalysisPipeline()
