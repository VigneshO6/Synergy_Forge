"""
Deep Learning (DL) Engine for ONION SMART
Modernized Deep Learning pipeline powered by YOLO11 and MobileNetV3.
"""

from dl.dl_config import (
    YOLO_INPUT_SIZE,
    MOBILENET_INPUT_SIZE,
    MOBILENET_CLASSES,
    PRODUCE_CLASSES,
    STRICT_IOU_THRESHOLD,
    STRICT_IOA_THRESHOLD,
)
from dl.preprocessing import (
    load_image_rgb,
    apply_clahe_enhancement,
    preprocess_for_yolo,
    preprocess_for_mobilenet,
    extract_bulb_crop,
)
from dl.model_loader import get_dl_model_registry, DeepLearningModelRegistry
from dl.yolo_detector import yolo_detector, YoloOnionDetector
from dl.mobilenet_classifier import mobilenet_classifier, MobileNetProduceClassifier
from dl.deep_pipeline import deep_pipeline, DeepLearningAnalysisPipeline

__all__ = [
    "deep_pipeline",
    "DeepLearningAnalysisPipeline",
    "yolo_detector",
    "YoloOnionDetector",
    "mobilenet_classifier",
    "MobileNetProduceClassifier",
    "get_dl_model_registry",
    "DeepLearningModelRegistry",
    "load_image_rgb",
    "apply_clahe_enhancement",
    "preprocess_for_yolo",
    "preprocess_for_mobilenet",
    "extract_bulb_crop",
    "PRODUCE_CLASSES",
    "MOBILENET_CLASSES",
]
