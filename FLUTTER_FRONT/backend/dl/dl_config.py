"""
Deep Learning Configuration & Hyperparameters
Defines input dimensions, confidence thresholds, IoU/IoA non-overlapping criteria,
and strict 4-class produce categorization (Medium completely removed).
"""

from typing import List, Tuple

# Input dimensions for Deep Learning architectures
YOLO_INPUT_SIZE: Tuple[int, int] = (640, 640)
MOBILENET_INPUT_SIZE: Tuple[int, int] = (224, 224)

# YOLO11 Inference Parameters
YOLO_CONFIDENCE_THRESHOLD: float = 0.22
YOLO_IOU_THRESHOLD: float = 0.45

# Strict Zero-Overlap Bounding Box Suppression Parameters
# Guarantees no two bounding boxes overlap on the same onion bulb
STRICT_IOU_THRESHOLD: float = 0.18  # Max allowable Intersection-over-Union
STRICT_IOA_THRESHOLD: float = 0.28  # Max allowable Intersection-over-Area (catches nested boxes)

# Multi-scale Test-Time Augmentation (TTA) scales for YOLO11
TTA_SCALES: List[float] = [0.85, 1.0, 1.15]

# MobileNetV3 Quality Classes
MOBILENET_CLASSES: List[str] = ["Good", "Defective", "Sprouted"]

# Produce Final 4-Class Breakdown (Strictly NO Medium)
PRODUCE_CLASSES: List[str] = ["Good", "Defective", "Sprouted", "URS (Undersized)"]

# Undersized (URS) Caliber Threshold (relative to lot median bulb area)
URS_AREA_RATIO_THRESHOLD: float = 0.48

# Defect and Sprout Visual Heuristic Thresholds
SPROUT_PIXEL_RATIO_THRESHOLD: float = 0.025
DEFECT_PIXEL_RATIO_THRESHOLD: float = 0.08
